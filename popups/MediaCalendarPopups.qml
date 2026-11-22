import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import "../core"

Item {
    id: modRoot
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin
    required property var overlay
    readonly property bool anyVisible: (musicFullCard.opacity > 0.01 || calCard.opacity > 0.01)

        Rectangle {
            id: musicFullCard
            z: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 4
            width: 324
            height: 194
            topLeftRadius: 22
            topRightRadius: 22
            bottomLeftRadius: 22
            bottomRightRadius: 22
            color: ShellState.isSolid ? ThemeTokens.windowBg : "transparent"
            Canvas {
                                x: 0
                y: 0
                width: parent.width
                height: parent.height
                z: -1
                visible: !ShellState.isSolid
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
                property real dTh: shellRoot.activeGlassDetail
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDFChanged: requestPaint()
                onDWChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    let sw = Screen.width || 1366;
                        let sh = Screen.height || 768;
                        let pos = parent.mapToItem(null, 0, 0);
                        shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, 22, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: ThemeTokens.borderStrong
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "music" || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "music")
            property int stage: 0
            onIsOpenChanged: {
                if (isOpen) {
                    stage = 1;
                    musicStaggerTimer.restart();
                } else {
                    musicStaggerTimer.stop();
                    stage = 0;
                }
            }

            Timer {
                id: musicStaggerTimer
                interval: 34
                repeat: true
                onTriggered: {
                    if (musicFullCard.stage < 3) musicFullCard.stage++;
                    else stop();
                }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: musicFullCard.isOpen ? 0 : -12
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }
            transformOrigin: Item.Top

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

            Column {
                x: 16
                y: 14
                z: 2
                width: 292
                spacing: 12

                Row {
                    width: 292
                    spacing: 12
                    opacity: musicFullCard.stage >= 1 ? 1.0 : 0.0
                    transform: Translate {
                        y: musicFullCard.stage >= 1 ? 0 : 10
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 64; height: 64; radius: 14
                        color: "#2A2A32"; clip: true

                        Image {
                            id: fullArt
                            anchors.fill: parent
                            source: overlay.mediaPlayer ? overlay.mediaPlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            color: "#A1C6FF"
                            font.pixelSize: 24
                            visible: fullArt.status !== Image.Ready
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 214
                        spacing: 4

                        Text {
                            width: 214
                            text: (overlay.mediaPlayer && overlay.mediaPlayer.trackTitle)
                                  ? overlay.mediaPlayer.trackTitle : "Not Playing"
                            color: ThemeTokens.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: 214
                            text: (overlay.mediaPlayer && overlay.mediaPlayer.trackArtist)
                                  ? overlay.mediaPlayer.trackArtist : "MPRIS Media Player"
                            color: ThemeTokens.textSecondary
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        Text {
                            width: 214
                            text: (overlay.mediaPlayer && overlay.mediaPlayer.identity)
                                  ? overlay.mediaPlayer.identity : "Audio Output"
                            color: "#A1C6FF"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }

                Column {
                    width: 292
                    spacing: 5
                    opacity: musicFullCard.stage >= 2 ? 1.0 : 0.0
                    transform: Translate {
                        y: musicFullCard.stage >= 2 ? 0 : 10
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 292
                        height: 5
                        radius: 2.5
                        color: ThemeTokens.inputBg

                        Rectangle {
                            width: {
                                let _ = hostWin.tick;
                                return (overlay.mediaPlayer && overlay.mediaPlayer.length > 0)
                                    ? Math.min(292, 292 * (overlay.mediaPlayer.position / overlay.mediaPlayer.length)) : 0;
                            }
                            height: 5
                            radius: 2.5
                            color: "#A1C6FF"
                            Behavior on width { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                        }
                    }

                    RowLayout {
                        width: 292
                        Text {
                            text: { let _ = hostWin.tick; return overlay.mediaPlayer ? shellRoot.formatTime(overlay.mediaPlayer.position) : "0:00"; }
                            color: ThemeTokens.textMuted
                            font.pixelSize: 10
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: overlay.mediaPlayer ? shellRoot.formatTime(overlay.mediaPlayer.length) : "0:00"
                            color: ThemeTokens.textMuted
                            font.pixelSize: 10
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 22
                    opacity: musicFullCard.stage >= 3 ? 1.0 : 0.0
                    transform: Translate {
                        y: musicFullCard.stage >= 3 ? 0 : 10
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 38; height: 38; radius: 19
                        color: mpPrevM.containsMouse ? "#2EFFFFFF" : "#18FFFFFF"
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Text { anchors.centerIn: parent; text: "|◀"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                        MouseArea {
                            id: mpPrevM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (overlay.mediaPlayer) overlay.mediaPlayer.previous()
                        }
                    }

                    Rectangle {
                        width: 44; height: 44; radius: 22
                        color: "#A1C6FF"
                        scale: mpPlayM.pressed ? 0.90 : (mpPlayM.containsMouse ? 1.06 : 1.0)
                        Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
                        Text {
                            anchors.centerIn: parent
                            text: (overlay.mediaPlayer && overlay.mediaPlayer.isPlaying) ? "❚❚" : "▶"
                            color: ThemeTokens.cardBg
                            font.pixelSize: 13
                            font.bold: true
                        }
                        MouseArea {
                            id: mpPlayM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (overlay.mediaPlayer) overlay.mediaPlayer.togglePlaying()
                        }
                    }

                    Rectangle {
                        width: 38; height: 38; radius: 19
                        color: mpNextM.containsMouse ? "#2EFFFFFF" : "#18FFFFFF"
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Text { anchors.centerIn: parent; text: "▶|"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                        MouseArea {
                            id: mpNextM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (overlay.mediaPlayer) overlay.mediaPlayer.next()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: calCard
            z: 10
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 4
            anchors.rightMargin: 10
            width: 288
            height: calCol.implicitHeight + 24
            topLeftRadius: 20
            topRightRadius: 20
            bottomLeftRadius: 20
            bottomRightRadius: 20
            color: ShellState.isSolid ? ThemeTokens.windowBg : "transparent"
            Canvas {
                                x: 0
                y: 0
                width: parent.width
                height: parent.height
                z: -1
                visible: !ShellState.isSolid
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
                property real dTh: shellRoot.activeGlassDetail
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDFChanged: requestPaint()
                onDWChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    let sw = Screen.width || 1366;
                        let sh = Screen.height || 768;
                        let pos = parent.mapToItem(null, 0, 0);
                        shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, 20, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: ThemeTokens.borderStrong
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "calendar" || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }

            property int viewYear: (new Date()).getFullYear()
            property int viewMonth: (new Date()).getMonth()
            property var calendarCells: []

            function rebuildCalendar() {
                let firstDay = new Date(viewYear, viewMonth, 1).getDay();
                let daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
                let today = new Date();
                let isCurrentMonth = (today.getFullYear() === viewYear && today.getMonth() === viewMonth);
                let todayDate = today.getDate();

                let cells = [];
                for (let i = 0; i < firstDay; i++) {
                    cells.push({ day: 0, isToday: false });
                }
                for (let d = 1; d <= daysInMonth; d++) {
                    cells.push({ day: d, isToday: isCurrentMonth && d === todayDate });
                }
                while (cells.length % 7 !== 0) {
                    cells.push({ day: 0, isToday: false });
                }
                calendarCells = cells;
            }

            function monthTitle() {
                let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                return months[viewMonth] + " " + viewYear;
            }

            Component.onCompleted: rebuildCalendar()



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "calendar")
            property int stage: 0
            onIsOpenChanged: {
                if (isOpen) { stage = 0; calStagger.restart(); }
                else { calStagger.stop(); stage = 0; }
            }
            Timer {
                id: calStagger
                interval: 34; repeat: true
                onTriggered: { if (calCard.stage < 3) calCard.stage++; else stop(); }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: calCard.isOpen ? 0 : -12
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopRight

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

            ColumnLayout {
                id: calCol
                z: 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    opacity: calCard.stage >= 1 ? 1.0 : 0.0
                    transform: Translate {
                        y: calCard.stage >= 1 ? 0 : 8
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Text { text: calCard.monthTitle(); color: ThemeTokens.textPrimary; font.pixelSize: 14; font.bold: true }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: prevMoM.containsMouse ? "#2EFFFFFF" : "#1AFFFFFF"
                        Text { anchors.centerIn: parent; text: "‹"; color: ThemeTokens.textPrimary; font.pixelSize: 14; font.bold: true }
                        MouseArea {
                            id: prevMoM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (calCard.viewMonth === 0) { calCard.viewMonth = 11; calCard.viewYear--; }
                                else calCard.viewMonth--;
                                calCard.rebuildCalendar();
                            }
                        }
                    }

                    Rectangle {
                        width: 44; height: 24; radius: 12
                        color: todayMoM.containsMouse ? "#2EFFFFFF" : "#1AFFFFFF"
                        Text { anchors.centerIn: parent; text: "Today"; color: ThemeTokens.textPrimary; font.pixelSize: 10; font.bold: true }
                        MouseArea {
                            id: todayMoM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let n = new Date();
                                calCard.viewYear = n.getFullYear();
                                calCard.viewMonth = n.getMonth();
                                calCard.rebuildCalendar();
                            }
                        }
                    }

                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: nextMoM.containsMouse ? "#2EFFFFFF" : "#1AFFFFFF"
                        Text { anchors.centerIn: parent; text: "›"; color: ThemeTokens.textPrimary; font.pixelSize: 14; font.bold: true }
                        MouseArea {
                            id: nextMoM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (calCard.viewMonth === 11) { calCard.viewMonth = 0; calCard.viewYear++; }
                                else calCard.viewMonth++;
                                calCard.rebuildCalendar();
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 4
                    rowSpacing: 4
                    opacity: calCard.stage >= 2 ? 1.0 : 0.0
                    transform: Translate {
                        y: calCard.stage >= 2 ? 0 : 8
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: index === 0 ? "#FF453A" : "#8E8E93"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: calCard.calendarCells

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 14
                            color: modelData.isToday ? "#FF3B30" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day > 0 ? modelData.day : ""
                                color: modelData.isToday ? "#FFFFFF" : "#F5F5F7"
                                font.pixelSize: 12
                                font.weight: modelData.isToday ? Font.Bold : Font.Normal
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 10
                    color: "#1EFFFFFF"
                    opacity: calCard.stage >= 3 ? 1.0 : 0.0
                    transform: Translate {
                        y: calCard.stage >= 3 ? 0 : 8
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text { text: "Niri 26.04 • ThinkPad AMD"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: shellRoot.batteryPercent >= 0 ? ("BAT " + shellRoot.batteryPercent + "%") : ""; color: "#32D74B"; font.pixelSize: 10; font.bold: true }
                    }
                }
            }
        }
}
