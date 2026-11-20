import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import "../core"

    PanelWindow {
        id: topBar
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "macos-menubar"
        exclusionMode: ExclusionMode.Auto

        anchors { top: true; left: true; right: true }
        implicitHeight: 28
        color: "transparent"

        property string dateTimeStr: ""
        property var mediaPlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

        function updateClock() {
            let d = new Date();
            let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            let hr = d.getHours();
            let ampm = hr >= 12 ? "PM" : "AM";
            hr = hr % 12;
            if (hr === 0) hr = 12;
            let min = d.getMinutes();
            let minStr = min < 10 ? "0" + min : "" + min;
            dateTimeStr = days[d.getDay()] + " " + months[d.getMonth()] + " " + d.getDate() + "  " + hr + ":" + minStr + " " + ampm;
        }

        Component.onCompleted: updateClock()

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: topBar.updateClock()
        }

        Rectangle {
            id: topBarSurface
            anchors.fill: parent
            color: "#8A141418"
            opacity: ShellState.bootStage >= 1 ? 1.0 : 0.0
            transform: Translate {
                y: ShellState.bootStage >= 1 ? 0 : -28
                Behavior on y { SpringAnimation { spring: 7.5; damping: 0.72 } }
            }
            Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#1FFFFFFF"
            }

            // ZONA KIRI
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    width: 28
                    height: 22
                    radius: 6
                    color: (ShellState.activePopup === "apple" || logoM.containsMouse) ? "#2EFFFFFF" : "transparent"
                    scale: logoM.pressed ? 0.92 : (logoM.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                    Canvas {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "#F5F5F7";
                            ctx.beginPath();
                            ctx.arc(7, 8.6, 4.6, 0, Math.PI * 2);
                            ctx.fill();
                            ctx.fillStyle = "#18181E";
                            ctx.beginPath();
                            ctx.arc(11.4, 7.8, 2.2, 0, Math.PI * 2);
                            ctx.fill();
                            ctx.fillStyle = "#F5F5F7";
                            ctx.beginPath();
                            ctx.ellipse(7.2, 1.3, 2.4, 1.3, -0.6, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }

                    MouseArea {
                        id: logoM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: ShellState.switchPopup("apple")
                    }
                }

                Rectangle {
                    height: 22
                    width: appTitleTxt.implicitWidth + 12
                    radius: 6
                    color: "transparent"

                    Text {
                        id: appTitleTxt
                        anchors.centerIn: parent
                        text: ShellState.focusedAppName
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    height: 22
                    width: winMenuTxt.implicitWidth + 14
                    radius: 6
                    color: (ShellState.activePopup === "window" || winMenuM.containsMouse) ? "#2EFFFFFF" : "transparent"
                    scale: winMenuM.pressed ? 0.94 : (winMenuM.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                    Text {
                        id: winMenuTxt
                        anchors.centerIn: parent
                        text: "Window"
                        color: "#E5F5F7"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: winMenuM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: ShellState.switchPopup("window")
                    }
                }

                Rectangle {
                    height: 22
                    width: deskMenuTxt.implicitWidth + 14
                    radius: 6
                    color: (ShellState.activePopup === "desktop" || deskMenuM.containsMouse) ? "#2EFFFFFF" : "transparent"
                    scale: deskMenuM.pressed ? 0.94 : (deskMenuM.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                    Text {
                        id: deskMenuTxt
                        anchors.centerIn: parent
                        text: "Desktop"
                        color: "#E5F5F7"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: deskMenuM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: ShellState.switchPopup("desktop")
                    }
                }
            }

            // ZONA TENGAH: MUSIC PLAYER PILL
            Timer {
                id: musicHoverOpenTimer
                interval: 160
                repeat: false
                onTriggered: {
                    if (ShellState.activePopup !== "music") {
                        ShellState.musicPreviewVisible = true;
                    }
                }
            }

            Timer {
                id: musicPreviewCloseTimer
                interval: 260
                repeat: false
                onTriggered: {
                    if (!npPillM.containsMouse && !musicPreviewHover.hovered) {
                        ShellState.musicPreviewVisible = false;
                    }
                }
            }

            Rectangle {
                id: centerMusicPill
                anchors.centerIn: parent
                height: 21
                width: Math.min(276, nowPlayingRow.implicitWidth + 20)
                radius: 10.5
                color: (ShellState.activePopup === "music" || ShellState.musicPreviewVisible || npPillM.containsMouse) ? "#38FFFFFF" : "#22FFFFFF"
                border.width: 1
                border.color: (ShellState.activePopup === "music" || ShellState.musicPreviewVisible) ? "#55A1C6FF" : "#28FFFFFF"
                scale: npPillM.pressed ? 0.95 : (npPillM.containsMouse ? 1.03 : 1.0)

                Behavior on color { ColorAnimation { duration: 60 } }
                Behavior on border.color { ColorAnimation { duration: 180 } }
                Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }
                Behavior on width { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                Row {
                    id: nowPlayingRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        radius: 7
                        color: (topBar.mediaPlayer && topBar.mediaPlayer.isPlaying) ? "#32D74B" : "#A1C6FF"
                        Behavior on color { ColorAnimation { duration: 220 } }

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            color: "#141418"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (topBar.mediaPlayer && topBar.mediaPlayer.trackTitle !== "")
                              ? topBar.mediaPlayer.trackTitle : "Music"
                        color: "#F5F5F7"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: Math.min(205, implicitWidth)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (ShellState.activePopup === "music" || ShellState.musicPreviewVisible) ? "▴" : "▾"
                        color: "#AEAEB2"
                        font.pixelSize: 9
                    }
                }

                MouseArea {
                    id: npPillM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        musicPreviewCloseTimer.stop();
                        if (ShellState.activePopup !== "music") {
                            musicHoverOpenTimer.restart();
                        }
                    }
                    onExited: {
                        musicHoverOpenTimer.stop();
                        musicPreviewCloseTimer.restart();
                    }
                    onClicked: {
                        musicHoverOpenTimer.stop();
                        ShellState.musicPreviewVisible = false;
                        ShellState.switchPopup("music");
                    }
                }
            }

            // ZONA KANAN
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    height: 22
                    width: batRow.implicitWidth + 10
                    radius: 6
                    color: "transparent"
                    visible: ShellState.batteryPercent >= 0

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ShellState.batteryPercent + "%"
                            color: "#E5F5F7"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 11

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 19
                                height: 11
                                radius: 3
                                color: "transparent"
                                border.width: 1
                                border.color: "#AAF5F5F7"

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(2, Math.round(15 * (ShellState.batteryPercent / 100)))
                                    height: 7
                                    radius: 1.5
                                    color: ShellState.batteryStatus === "Charging" ? "#32D74B"
                                         : (ShellState.batteryPercent <= 20 ? "#FF453A" : "#F5F5F7")
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: 4
                                radius: 1
                                color: "#AAF5F5F7"
                            }
                        }
                    }
                }

                Rectangle {
                    width: 26
                    height: 22
                    radius: 6
                    color: (ShellState.activePopup === "wifi" || wifiTopM.containsMouse) ? "#2EFFFFFF" : "transparent"
                    scale: wifiTopM.pressed ? 0.92 : (wifiTopM.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                    Canvas {
                        id: topWifiCanvas
                        anchors.centerIn: parent
                        width: 16
                        height: 14
                        property bool active: ShellState.wifiConnected
                        onActiveChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = active ? "#F5F5F7" : "#66F5F5F7";
                            ctx.lineWidth = 1.5;
                            ctx.lineCap = "round";
                            for (let r = 3; r <= 9; r += 3) {
                                ctx.beginPath();
                                ctx.arc(8, 11.5, r, -Math.PI * 0.78, -Math.PI * 0.22);
                                ctx.stroke();
                            }
                            ctx.fillStyle = active ? "#F5F5F7" : "#66F5F5F7";
                            ctx.beginPath();
                            ctx.arc(8, 11.8, 1.3, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }

                    MouseArea {
                        id: wifiTopM
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) ShellState.switchPopup("wifi");
                            else ShellState.switchPopup("cc");
                        }
                    }
                }

                Rectangle {
                    width: 26
                    height: 22
                    radius: 6
                    color: spotM.containsMouse ? "#2EFFFFFF" : "transparent"
                    scale: spotM.pressed ? 0.92 : (spotM.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                    Canvas {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "#F5F5F7";
                            ctx.lineWidth = 1.6;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(6, 6, 4.2, 0, Math.PI * 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(9.2, 9.2);
                            ctx.lineTo(12.5, 12.5);
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        id: spotM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: ShellState.switchPopup("spotlight")
                    }
                }

                Rectangle {
                    width: 28
                    height: 22
                    radius: 6
                    color: (ShellState.activePopup === "cc" || ccTopM.containsMouse) ? "#34FFFFFF" : "transparent"
                    scale: ccTopM.pressed ? 0.92 : (ccTopM.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                    Canvas {
                        anchors.centerIn: parent
                        width: 16
                        height: 14
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "#F5F5F7";
                            ctx.fillStyle = "#F5F5F7";
                            ctx.lineWidth = 1.2;
                            ctx.beginPath();
                            ctx.roundedRect(2, 2, 12, 4, 2, 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(11.5, 4, 1.5, 0, Math.PI * 2);
                            ctx.fill();
                            ctx.beginPath();
                            ctx.roundedRect(2, 8, 12, 4, 2, 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(4.5, 10, 1.5, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }

                    MouseArea {
                        id: ccTopM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: ShellState.switchPopup("cc")
                    }
                }

                Rectangle {
                    height: 22
                    width: clockTxt.implicitWidth + 12
                    radius: 6
                    color: (ShellState.activePopup === "calendar" || clockTopM.containsMouse) ? "#2EFFFFFF" : "transparent"
                    scale: clockTopM.pressed ? 0.94 : (clockTopM.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                    Text {
                        id: clockTxt
                        anchors.centerIn: parent
                        text: topBar.dateTimeStr
                        color: "#F5F5F7"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: clockTopM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: ShellState.switchPopup("calendar")
                    }
                }
            }
        }
    }

