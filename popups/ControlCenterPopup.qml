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
    anchors.fill: parent
    required property var root
    required property var win
    required property var overlay
    readonly property bool anyVisible: (ccCard.opacity > 0.01)

        Rectangle {
            id: ccCard
            z: 10
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 4
            anchors.rightMargin: 10
            width: 338
            height: 460
            radius: 22
            color: "transparent"
            Canvas {
                anchors.fill: parent
                z: -1
                property real dO: root.aeroOpacity
                property real dR: root.aeroReflection
                property real dF: root.glassFade
                property string dW: root.activeGlassWall
                property string dSt: root.glassStyle
                property real dTh: root.activeGlassDetail
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDFChanged: requestPaint()
                onDWChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: {
                    let sw = Screen.width || 1366;
                    let sh = Screen.height || 768;
                    let pos = parent.mapToItem(null, 0, 0);
                    root.drawGlobalAeroGlass(getContext("2d"), width, height, parent.radius, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: "#38FFFFFF"
            visible: !root.preWarmDone || (root.activePopup === "cc" || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }

            property bool isOpen: root.activePopup === "cc"
            property int stage: 0
            onIsOpenChanged: {
                if (isOpen) {
                    stage = 1;
                    ccStaggerTimer.restart();
                } else {
                    ccStaggerTimer.stop();
                    stage = 0;
                }
            }

            Timer {
                id: ccStaggerTimer
                interval: 34
                repeat: true
                onTriggered: {
                    if (ccCard.stage < 5) ccCard.stage++;
                    else stop();
                }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: ccCard.isOpen ? 0 : -12
                Behavior on y { SpringAnimation { spring: 7.5; damping: 0.72 } }
            }
            transformOrigin: Item.TopRight

            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }
            Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

            Column {
                x: 12
                y: 12
                z: 2
                width: 314
                spacing: 10

                // BARIS 1: KONEKTIVITAS + FOCUS & CAPTURE (STAGE 1)
                Row {
                    width: 314
                    height: 154
                    spacing: 10
                    opacity: ccCard.stage >= 1 ? 1.0 : 0.0
                    transform: Translate {
                        y: ccCard.stage >= 1 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                    Rectangle {
                        width: 152
                        height: 154
                        radius: 18
                        color: "#22FFFFFF"
                        border.width: 1
                        border.color: "#1AFFFFFF"

                        Column {
                            x: 10
                            y: 10
                            width: 132
                            spacing: 7

                            // 1. Wi-Fi
                            Rectangle {
                                width: 132
                                height: 40
                                radius: 11
                                color: wifiRowM.containsMouse ? "#24FFFFFF" : "transparent"
                                Behavior on color { ColorAnimation { duration: 160 } }

                                Rectangle {
                                    x: 2; y: 3
                                    width: 34; height: 34; radius: 17
                                    color: root.wifiEnabled ? "#0A84FF" : "#3A3A40"
                                    Behavior on color { ColorAnimation { duration: 220 } }

                                    Canvas {
                                        anchors.centerIn: parent
                                        width: 16; height: 14
                                        onPaint: {
                                            let ctx = getContext("2d"); ctx.reset();
                                            ctx.strokeStyle = "#FFFFFF"; ctx.lineWidth = 1.6; ctx.lineCap = "round";
                                            for (let r = 3; r <= 9; r += 3) {
                                                ctx.beginPath();
                                                ctx.arc(8, 11.5, r, -Math.PI * 0.78, -Math.PI * 0.22);
                                                ctx.stroke();
                                            }
                                            ctx.fillStyle = "#FFFFFF";
                                            ctx.beginPath(); ctx.arc(8, 11.8, 1.3, 0, Math.PI * 2); ctx.fill();
                                        }
                                    }
                                }

                                Text { x: 44; y: 4; width: 74; text: "Wi-Fi"; color: "#F5F5F7"; font.pixelSize: 12; font.bold: true }
                                Text { x: 44; y: 20; width: 74; text: root.wifiName; color: "#AEAEB2"; font.pixelSize: 10; elide: Text.ElideRight }
                                Text { x: 121; y: 12; text: "›"; color: "#8E8E93"; font.pixelSize: 13; font.bold: true }

                                MouseArea {
                                    id: wifiRowM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton || mouse.x > 110) root.switchPopup("wifi");
                                        else root.toggleWifi();
                                    }
                                }
                            }

                            // 2. Bluetooth
                            Rectangle {
                                width: 132
                                height: 40
                                radius: 11
                                color: btRowM.containsMouse ? "#24FFFFFF" : "transparent"
                                Behavior on color { ColorAnimation { duration: 160 } }

                                Rectangle {
                                    x: 2; y: 3
                                    width: 34; height: 34; radius: 17
                                    color: root.btEnabled ? "#0A84FF" : "#3A3A40"
                                    Behavior on color { ColorAnimation { duration: 220 } }

                                    Canvas {
                                        anchors.centerIn: parent
                                        width: 14; height: 16
                                        onPaint: {
                                            let ctx = getContext("2d"); ctx.reset();
                                            ctx.strokeStyle = "#FFFFFF"; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round";
                                            ctx.beginPath();
                                            ctx.moveTo(4, 5); ctx.lineTo(10, 11); ctx.lineTo(7, 14);
                                            ctx.moveTo(7, 2); ctx.lineTo(7, 14);
                                            ctx.moveTo(7, 2); ctx.lineTo(10, 5); ctx.lineTo(4, 11);
                                            ctx.stroke();
                                        }
                                    }
                                }

                                Text { x: 44; y: 4; width: 74; text: "Bluetooth"; color: "#F5F5F7"; font.pixelSize: 12; font.bold: true }
                                Text { x: 44; y: 20; width: 74; text: root.btEnabled ? (root.btDeviceName !== "" ? root.btDeviceName : "Aktif") : "Mati"; color: "#AEAEB2"; font.pixelSize: 10; elide: Text.ElideRight }
                                Text { x: 121; y: 12; text: "›"; color: "#8E8E93"; font.pixelSize: 13; font.bold: true }

                                MouseArea {
                                    id: btRowM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton || mouse.x > 110) root.switchPopup("bt");
                                        else root.toggleBluetooth();
                                    }
                                }
                            }

                            // 3. Keep Awake
                            Rectangle {
                                width: 132
                                height: 40
                                radius: 11
                                color: awakeRowM.containsMouse ? "#24FFFFFF" : "transparent"
                                Behavior on color { ColorAnimation { duration: 160 } }

                                Rectangle {
                                    x: 2; y: 3
                                    width: 34; height: 34; radius: 17
                                    color: root.keepAwake ? "#FF9F0A" : "#3A3A40"
                                    Behavior on color { ColorAnimation { duration: 220 } }

                                    Canvas {
                                        anchors.centerIn: parent
                                        width: 14; height: 14
                                        onPaint: {
                                            let ctx = getContext("2d"); ctx.reset();
                                            ctx.strokeStyle = "#FFFFFF"; ctx.lineWidth = 1.6;
                                            ctx.beginPath(); ctx.arc(7, 7, 4.5, 0, Math.PI * 2); ctx.stroke();
                                            ctx.beginPath(); ctx.moveTo(7, 4.5); ctx.lineTo(7, 7.2); ctx.lineTo(9, 8.8); ctx.stroke();
                                        }
                                    }
                                }

                                Text { x: 44; y: 4; width: 84; text: "Keep Awake"; color: "#F5F5F7"; font.pixelSize: 12; font.bold: true }
                                Text { x: 44; y: 20; width: 84; text: root.keepAwake ? "Layar Terjaga" : "Normal"; color: "#AEAEB2"; font.pixelSize: 10; elide: Text.ElideRight }

                                MouseArea {
                                    id: awakeRowM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleKeepAwake()
                                }
                            }
                        }
                    }

                    Column {
                        width: 152
                        height: 154
                        spacing: 10

                        Rectangle {
                            width: 152
                            height: 72
                            radius: 18
                            color: dndM.containsMouse ? "#30FFFFFF" : "#22FFFFFF"
                            border.width: 1
                            border.color: "#1AFFFFFF"
                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                x: 12; y: 18
                                width: 36; height: 36; radius: 18
                                color: root.dndEnabled ? "#5E5CE6" : "#3A3A40"
                                Behavior on color { ColorAnimation { duration: 220 } }

                                Canvas {
                                    anchors.centerIn: parent
                                    width: 16; height: 16
                                    onPaint: {
                                        let ctx = getContext("2d"); ctx.reset();
                                        ctx.fillStyle = "#FFFFFF";
                                        ctx.beginPath();
                                        ctx.arc(8.5, 8, 5.2, 0.35 * Math.PI, 1.65 * Math.PI);
                                        ctx.arc(11.2, 6.2, 4.2, 1.55 * Math.PI, 0.45 * Math.PI, true);
                                        ctx.closePath();
                                        ctx.fill();
                                    }
                                }
                            }

                            Text { x: 56; y: 19; width: 86; text: "Focus"; color: "#F5F5F7"; font.pixelSize: 12; font.bold: true }
                            Text { x: 56; y: 36; width: 86; text: root.dndEnabled ? "Do Not Disturb" : "Off"; color: "#AEAEB2"; font.pixelSize: 10; elide: Text.ElideRight }

                            MouseArea {
                                id: dndM
                                anchors.fill: parent
                                z: 5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleDnd()
                            }
                        }

                        Row {
                            width: 152
                            height: 72
                            spacing: 10

                            Rectangle {
                                width: 71
                                height: 72
                                radius: 18
                                color: ssTileM.containsMouse ? "#30FFFFFF" : "#22FFFFFF"
                                border.width: 1
                                border.color: "#1AFFFFFF"
                                scale: ssTileM.pressed ? 0.94 : 1.0
                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                Canvas {
                                    x: 25; y: 14
                                    width: 20; height: 18
                                    onPaint: {
                                        let ctx = getContext("2d"); ctx.reset();
                                        ctx.strokeStyle = "#F5F5F7"; ctx.lineWidth = 1.6;
                                        ctx.strokeRect(2, 4, 16, 11);
                                        ctx.beginPath(); ctx.arc(10, 9.5, 3, 0, Math.PI * 2); ctx.stroke();
                                    }
                                }

                                Text { x: 4; y: 42; width: 63; horizontalAlignment: Text.AlignHCenter; text: "Capture"; color: "#F5F5F7"; font.pixelSize: 11; font.weight: Font.Medium }

                                MouseArea {
                                    id: ssTileM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.closePopups();
                                        screenshotDelayTimer.restart();
                                    }
                                }
                            }

                            Rectangle {
                                width: 71
                                height: 72
                                radius: 18
                                color: wpTileM.containsMouse ? "#30FFFFFF" : "#22FFFFFF"
                                border.width: 1
                                border.color: "#1AFFFFFF"
                                scale: wpTileM.pressed ? 0.94 : 1.0
                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                Canvas {
                                    x: 25; y: 14
                                    width: 20; height: 18
                                    onPaint: {
                                        let ctx = getContext("2d"); ctx.reset();
                                        ctx.strokeStyle = "#FF9F0A"; ctx.lineWidth = 1.6;
                                        ctx.strokeRect(2, 3, 16, 12);
                                        ctx.beginPath(); ctx.moveTo(3, 14); ctx.lineTo(8, 8); ctx.lineTo(12, 12); ctx.lineTo(14, 9); ctx.lineTo(17, 14); ctx.stroke();
                                    }
                                }

                                Text { x: 4; y: 42; width: 63; horizontalAlignment: Text.AlignHCenter; text: "Wallpaper"; color: "#F5F5F7"; font.pixelSize: 11; font.weight: Font.Medium }

                                MouseArea {
                                    id: wpTileM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.pickRandomWallpaper()
                                }
                            }
                        }
                    }
                }

                // BARIS 2: DISPLAY BRIGHTNESS SLIDER (STAGE 2)
                Rectangle {
                    width: 314
                    height: 66
                    radius: 18
                    color: "#22FFFFFF"
                    border.width: 1
                    border.color: "#1AFFFFFF"
                    opacity: ccCard.stage >= 2 ? 1.0 : 0.0
                    transform: Translate {
                        y: ccCard.stage >= 2 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                    Text { x: 14; y: 10; text: "Display"; color: "#F5F5F7"; font.pixelSize: 11; font.bold: true }
                    Text { anchors.right: parent.right; anchors.rightMargin: 14; y: 10; text: root.brightnessLevel + "%"; color: "#AEAEB2"; font.pixelSize: 11 }

                    Rectangle {
                        id: briTrack
                        x: 12; y: 32
                        width: 290
                        height: 24
                        radius: 12
                        color: "#38000000"
                        clip: true

                        Rectangle {
                            width: Math.max(24, 290 * (root.brightnessLevel / 100))
                            height: 24
                            radius: 12
                            color: "#F5F5F7"
                            Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.InOutCubic } }
                        }

                        Canvas {
                            x: 6; y: 6
                            width: 12; height: 12
                            onPaint: {
                                let ctx = getContext("2d"); ctx.reset();
                                ctx.fillStyle = "#1C1C22";
                                ctx.beginPath(); ctx.arc(6, 6, 3.2, 0, Math.PI * 2); ctx.fill();
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (m) => root.setBrightnessPct((m.x / 290) * 100)
                            onPositionChanged: (m) => { if (pressed) root.setBrightnessPct((m.x / 290) * 100); }
                        }
                    }
                }

                // BARIS 3: SOUND VOLUME SLIDER (STAGE 3)
                Rectangle {
                    width: 314
                    height: 66
                    radius: 18
                    color: "#22FFFFFF"
                    border.width: 1
                    border.color: "#1AFFFFFF"
                    opacity: ccCard.stage >= 3 ? 1.0 : 0.0
                    transform: Translate {
                        y: ccCard.stage >= 3 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                    Text { x: 14; y: 10; text: "Sound"; color: "#F5F5F7"; font.pixelSize: 11; font.bold: true }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        y: 10
                        text: root.volumeMuted ? "Muted" : (root.volumeLevel + "%")
                        color: root.volumeMuted ? "#FF453A" : "#AEAEB2"
                        font.pixelSize: 11

                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMute()
                        }
                    }

                    Rectangle {
                        id: volTrack
                        x: 12; y: 32
                        width: 290
                        height: 24
                        radius: 12
                        color: "#38000000"
                        clip: true

                        Rectangle {
                            width: root.volumeMuted ? 24 : Math.max(24, 290 * (root.volumeLevel / 100))
                            height: 24
                            radius: 12
                            color: "#F5F5F7"
                            Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.InOutCubic } }
                        }

                        Canvas {
                            x: 6; y: 6
                            width: 12; height: 12
                            onPaint: {
                                let ctx = getContext("2d"); ctx.reset();
                                ctx.fillStyle = "#1C1C22";
                                ctx.beginPath();
                                ctx.moveTo(2, 4.5); ctx.lineTo(4.5, 4.5); ctx.lineTo(8, 2);
                                ctx.lineTo(8, 10); ctx.lineTo(4.5, 7.5); ctx.lineTo(2, 7.5);
                                ctx.closePath(); ctx.fill();
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (m) => root.setVolumePct((m.x / 290) * 100)
                            onPositionChanged: (m) => { if (pressed) root.setVolumePct((m.x / 290) * 100); }
                        }
                    }
                }

                // BARIS 4: NOW PLAYING MEDIA CARD (STAGE 4)
                Rectangle {
                    width: 314
                    height: 72
                    radius: 18
                    color: "#22FFFFFF"
                    border.width: 1
                    border.color: "#1AFFFFFF"
                    opacity: ccCard.stage >= 4 ? 1.0 : 0.0
                    transform: Translate {
                        y: ccCard.stage >= 4 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                    Rectangle {
                        x: 12; y: 12
                        width: 48; height: 48; radius: 11
                        color: "#2C2C34"
                        clip: true

                        Image {
                            id: ccArt
                            anchors.fill: parent
                            source: overlay.mediaPlayer ? overlay.mediaPlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            color: "#A1C6FF"
                            font.pixelSize: 19
                            visible: ccArt.status !== Image.Ready
                        }
                    }

                    Text {
                        x: 70; y: 18
                        width: 134
                        text: (overlay.mediaPlayer && overlay.mediaPlayer.trackTitle) ? overlay.mediaPlayer.trackTitle : "Not Playing"
                        color: "#F5F5F7"
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        x: 70; y: 37
                        width: 134
                        text: (overlay.mediaPlayer && overlay.mediaPlayer.trackArtist) ? overlay.mediaPlayer.trackArtist : "MPRIS Audio"
                        color: "#AEAEB2"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Row {
                        x: 210; y: 21
                        spacing: 4

                        Rectangle {
                            width: 28; height: 30; radius: 15
                            color: ccPrevM.containsMouse ? "#33FFFFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 60 } }
                            Text { anchors.centerIn: parent; text: "|◀"; color: "#F5F5F7"; font.pixelSize: 10 }
                            MouseArea {
                                id: ccPrevM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: if (overlay.mediaPlayer) overlay.mediaPlayer.previous()
                            }
                        }

                        Rectangle {
                            width: 32; height: 30; radius: 15
                            color: ccPlayM.containsMouse ? "#33FFFFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 60 } }
                            Text {
                                anchors.centerIn: parent
                                text: (overlay.mediaPlayer && overlay.mediaPlayer.isPlaying) ? "❚❚" : "▶"
                                color: "#F5F5F7"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                id: ccPlayM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: if (overlay.mediaPlayer) overlay.mediaPlayer.togglePlaying()
                            }
                        }

                        Rectangle {
                            width: 28; height: 30; radius: 15
                            color: ccNextM.containsMouse ? "#33FFFFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 60 } }
                            Text { anchors.centerIn: parent; text: "▶|"; color: "#F5F5F7"; font.pixelSize: 10 }
                            MouseArea {
                                id: ccNextM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: if (overlay.mediaPlayer) overlay.mediaPlayer.next()
                            }
                        }
                    }
                }

                // BARIS 5: BATTERY + ATUR WIDGET + SETTINGS + LOCK (STAGE 5)
                Row {
                    width: 314
                    height: 38
                    spacing: 8
                    opacity: ccCard.stage >= 5 ? 1.0 : 0.0
                    transform: Translate {
                        y: ccCard.stage >= 5 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                    Rectangle {
                        width: 94
                        height: 38
                        radius: 13
                        color: "#22FFFFFF"
                        border.width: 1
                        border.color: "#1AFFFFFF"

                        Text {
                            anchors.centerIn: parent
                            text: root.batteryPercent >= 0 ? ("BAT " + root.batteryPercent + "%") : "AC Power"
                            color: root.batteryStatus === "Charging" ? "#32D74B" : "#F5F5F7"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: 78
                        height: 38
                        radius: 13
                        color: ccEditM.containsMouse ? "#38FFFFFF" : "#22FFFFFF"
                        border.width: 1
                        border.color: "#1AFFFFFF"
                        Behavior on color { ColorAnimation { duration: 60 } }

                        Text { anchors.centerIn: parent; text: "Atur Widget"; color: "#F5F5F7"; font.pixelSize: 11; font.bold: true }

                        MouseArea {
                            id: ccEditM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closePopups();
                                win.posY = win.resolvedY;
                                win.editMode = true;
                            }
                        }
                    }

                    Rectangle {
                        width: 66
                        height: 38
                        radius: 13
                        color: ccSetM.containsMouse ? "#38FFFFFF" : "#22FFFFFF"
                        border.width: 1
                        border.color: "#1AFFFFFF"
                        Behavior on color { ColorAnimation { duration: 60 } }

                        Text { anchors.centerIn: parent; text: "Settings"; color: "#F5F5F7"; font.pixelSize: 11; font.bold: true }

                        MouseArea {
                            id: ccSetM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onPressed: root.switchPopup("settings")
                        }
                    }

                    Rectangle {
                        width: 52
                        height: 38
                        radius: 13
                        color: ccLockM.containsMouse ? "#38FFFFFF" : "#22FFFFFF"
                        border.width: 1
                        border.color: "#1AFFFFFF"
                        Behavior on color { ColorAnimation { duration: 60 } }

                        Text { anchors.centerIn: parent; text: "Lock"; color: "#F5F5F7"; font.pixelSize: 11; font.bold: true }

                        MouseArea {
                            id: ccLockM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closePopups();
                                root.runCmd("swaylock -f -c 000000 || loginctl lock-session");
                            }
                        }
                    }
                }
            }
        }
}
