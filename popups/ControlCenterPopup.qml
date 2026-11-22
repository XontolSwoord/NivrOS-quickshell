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
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "cc" || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "cc")
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
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopRight

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

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
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 152
                        height: 154
                        radius: 18
                        color: ThemeTokens.cardBg
                        border.width: 1
                        border.color: ThemeTokens.cardBg

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
                                transformOrigin: Item.Center
                                scale: wifiRowM.pressed ? 0.90 : (wifiRowM.containsMouse ? 1.015 : 1.0)
                                Behavior on scale { SpringAnimation { mass: 0.72; spring: 9.0; damping: 0.40; epsilon: 0.001 } }
                                Behavior on color { ColorAnimation { duration: 160 } }

                                Rectangle {
                                    x: 2; y: 3
                                    width: 34; height: 34; radius: 17
                                    color: shellRoot.wifiEnabled ? "#0A84FF" : "#3A3A40"
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

                                Text { x: 44; y: 4; width: 74; text: "Wi-Fi"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                                Text { x: 44; y: 20; width: 74; text: shellRoot.wifiName; color: ThemeTokens.textSecondary; font.pixelSize: 10; elide: Text.ElideRight }
                                Text { x: 121; y: 12; text: "›"; color: ThemeTokens.textMuted; font.pixelSize: 13; font.bold: true }

                                MouseArea {
                                    id: wifiRowM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton || mouse.x > 110) shellRoot.switchPopup("wifi");
                                        else shellRoot.toggleWifi();
                                    }
                                }
                            }

                            // 2. Bluetooth
                            Rectangle {
                                width: 132
                                height: 40
                                radius: 11
                                color: btRowM.containsMouse ? "#24FFFFFF" : "transparent"
                                transformOrigin: Item.Center
                                scale: btRowM.pressed ? 0.90 : (btRowM.containsMouse ? 1.015 : 1.0)
                                Behavior on scale { SpringAnimation { mass: 0.72; spring: 9.0; damping: 0.40; epsilon: 0.001 } }
                                Behavior on color { ColorAnimation { duration: 160 } }

                                Rectangle {
                                    x: 2; y: 3
                                    width: 34; height: 34; radius: 17
                                    color: shellRoot.btEnabled ? "#0A84FF" : "#3A3A40"
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

                                Text { x: 44; y: 4; width: 74; text: "Bluetooth"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                                Text { x: 44; y: 20; width: 74; text: shellRoot.btEnabled ? (shellRoot.btDeviceName !== "" ? shellRoot.btDeviceName : "Aktif") : "Mati"; color: ThemeTokens.textSecondary; font.pixelSize: 10; elide: Text.ElideRight }
                                Text { x: 121; y: 12; text: "›"; color: ThemeTokens.textMuted; font.pixelSize: 13; font.bold: true }

                                MouseArea {
                                    id: btRowM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton || mouse.x > 110) shellRoot.switchPopup("bt");
                                        else shellRoot.toggleBluetooth();
                                    }
                                }
                            }

                            // 3. Keep Awake
                            Rectangle {
                                width: 132
                                height: 40
                                radius: 11
                                color: awakeRowM.containsMouse ? "#24FFFFFF" : "transparent"
                                transformOrigin: Item.Center
                                scale: awakeRowM.pressed ? 0.90 : (awakeRowM.containsMouse ? 1.015 : 1.0)
                                Behavior on scale { SpringAnimation { mass: 0.72; spring: 9.0; damping: 0.40; epsilon: 0.001 } }
                                Behavior on color { ColorAnimation { duration: 160 } }

                                Rectangle {
                                    x: 2; y: 3
                                    width: 34; height: 34; radius: 17
                                    color: shellRoot.keepAwake ? "#FF9F0A" : "#3A3A40"
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

                                Text { x: 44; y: 4; width: 84; text: "Keep Awake"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                                Text { x: 44; y: 20; width: 84; text: shellRoot.keepAwake ? "Layar Terjaga" : "Normal"; color: ThemeTokens.textSecondary; font.pixelSize: 10; elide: Text.ElideRight }

                                MouseArea {
                                    id: awakeRowM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.toggleKeepAwake()
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
                            transformOrigin: Item.Center
                            scale: dndM.pressed ? 0.90 : (dndM.containsMouse ? 1.015 : 1.0)
                            Behavior on scale { SpringAnimation { mass: 0.72; spring: 9.0; damping: 0.40; epsilon: 0.001 } }
                            border.width: 1
                            border.color: ThemeTokens.cardBg
                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                x: 12; y: 18
                                width: 36; height: 36; radius: 18
                                color: shellRoot.dndEnabled ? "#5E5CE6" : "#3A3A40"
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

                            Text { x: 56; y: 19; width: 86; text: "Focus"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                            Text { x: 56; y: 36; width: 86; text: shellRoot.dndEnabled ? "Do Not Disturb" : "Off"; color: ThemeTokens.textSecondary; font.pixelSize: 10; elide: Text.ElideRight }

                            MouseArea {
                                id: dndM
                                anchors.fill: parent
                                z: 5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shellRoot.toggleDnd()
                            }
                        }

                        Row {
                            width: 152
                            height: 72
                            spacing: 10

                            // Tombol Night Light (Filter Cahaya Biru)
                            Rectangle {
                                width: 71
                                height: 72
                                radius: 18
                                color: ShellState.nightLightEnabled ? ThemeTokens.accentSoft : (nlTileM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.cardBg)
                                border.width: 1
                                border.color: ShellState.nightLightEnabled ? ThemeTokens.accent : ThemeTokens.borderSubtle
                                transformOrigin: Item.Center
                                scale: nlTileM.pressed ? 0.89 : (nlTileM.containsMouse ? 1.02 : 1.0)
                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                                Canvas {
                                    x: 25; y: 13
                                    width: 20; height: 18
                                    property bool activeNl: ShellState.nightLightEnabled
                                    property color fg: activeNl ? "#FF9F0A" : ThemeTokens.iconTint
                                    onActiveNlChanged: requestPaint()
                                    onFgChanged: requestPaint()
                                    onPaint: {
                                        let ctx = getContext("2d"); ctx.reset();
                                        ctx.strokeStyle = fg; ctx.fillStyle = fg; ctx.lineWidth = 1.5;
                                        // Simbol Matahari Hangat + Filter
                                        ctx.beginPath(); ctx.arc(10, 9, 4.2, 0, Math.PI * 2);
                                        if (activeNl) ctx.fill(); else ctx.stroke();
                                        for (let a = 0; a < 8; a++) {
                                            let ang = a * Math.PI / 4;
                                            ctx.beginPath();
                                            ctx.moveTo(10 + Math.cos(ang) * 6.2, 9 + Math.sin(ang) * 6.2);
                                            ctx.lineTo(10 + Math.cos(ang) * 8.2, 9 + Math.sin(ang) * 8.2);
                                            ctx.stroke();
                                        }
                                    }
                                }

                                Text { x: 4; y: 37; width: 63; horizontalAlignment: Text.AlignHCenter; text: "Night Light"; color: ThemeTokens.textPrimary; font.pixelSize: 10; font.weight: Font.DemiBold }
                                Text { x: 4; y: 51; width: 63; horizontalAlignment: Text.AlignHCenter; text: ShellState.nightLightEnabled ? (ShellState.nightLightTemp + "K") : "Off"; color: ThemeTokens.textSecondary; font.pixelSize: 9 }

                                MouseArea {
                                    id: nlTileM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.toggleNightLight()
                                }
                            }

                            // Tombol Capture & Rekam Layar Terintegrasi
                            Rectangle {
                                width: 71
                                height: 72
                                radius: 18
                                color: ShellState.isRecording ? "#33FF453A" : (ssTileM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.cardBg)
                                border.width: 1
                                border.color: ShellState.isRecording ? ThemeTokens.danger : ThemeTokens.borderSubtle
                                transformOrigin: Item.Center
                                scale: ssTileM.pressed ? 0.89 : (ssTileM.containsMouse ? 1.02 : 1.0)
                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                                Canvas {
                                    x: 25; y: 13
                                    width: 20; height: 18
                                    property bool rec: ShellState.isRecording
                                    property color fg: rec ? "#FF453A" : ThemeTokens.iconTint
                                    onRecChanged: requestPaint()
                                    onFgChanged: requestPaint()
                                    onPaint: {
                                        let ctx = getContext("2d"); ctx.reset();
                                        ctx.strokeStyle = fg; ctx.fillStyle = fg; ctx.lineWidth = 1.6;
                                        ctx.beginPath(); ctx.roundedRect(2, 4, 16, 11, 2.5, 2.5); ctx.stroke();
                                        ctx.beginPath(); ctx.arc(10, 9.5, 3, 0, Math.PI * 2);
                                        if (rec) ctx.fill(); else ctx.stroke();
                                    }
                                }

                                Text { x: 4; y: 37; width: 63; horizontalAlignment: Text.AlignHCenter; text: ShellState.isRecording ? "Stop Rec" : "Capture"; color: ShellState.isRecording ? ThemeTokens.danger : ThemeTokens.textPrimary; font.pixelSize: 10; font.weight: Font.DemiBold }
                                Text { x: 4; y: 51; width: 63; horizontalAlignment: Text.AlignHCenter; text: ShellState.isRecording ? "Merekam" : "Area / Rec"; color: ThemeTokens.textSecondary; font.pixelSize: 9 }

                                MouseArea {
                                    id: ssTileM
                                    anchors.fill: parent
                                    z: 5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (ShellState.isRecording) {
                                            shellRoot.toggleScreenRecord();
                                        } else if (mouse.button === Qt.RightButton) {
                                            shellRoot.closePopups();
                                            shellRoot.toggleScreenRecord();
                                        } else {
                                            ccCaptureMenu.visible = !ccCaptureMenu.visible;
                                        }
                                    }
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
                    color: ThemeTokens.cardBg
                    border.width: 1
                    border.color: ThemeTokens.cardBg
                    opacity: ccCard.stage >= 2 ? 1.0 : 0.0
                    transform: Translate {
                        y: ccCard.stage >= 2 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Text { x: 14; y: 10; text: "Display"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.bold: true }
                    Text { anchors.right: parent.right; anchors.rightMargin: 14; y: 10; text: shellRoot.brightnessLevel + "%"; color: ThemeTokens.textSecondary; font.pixelSize: 11 }

                    Rectangle {
                        id: briTrack
                        x: 12; y: 32
                        width: 290
                        height: 24
                        radius: 12
                        color: ThemeTokens.inputBg
                        clip: true

                        Rectangle {
                            width: Math.max(24, 290 * (shellRoot.brightnessLevel / 100))
                            height: 24
                            radius: 12
                            color: ThemeTokens.textPrimary
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
                            onPressed: (m) => shellRoot.setBrightnessPct((m.x / 290) * 100)
                            onPositionChanged: (m) => { if (pressed) shellRoot.setBrightnessPct((m.x / 290) * 100); }
                        }
                    }
                }

                // BARIS 3: SOUND VOLUME SLIDER (STAGE 3)
                Rectangle {
                    width: 314
                    height: 66
                    radius: 18
                    color: ThemeTokens.cardBg
                    border.width: 1
                    border.color: ThemeTokens.cardBg
                    opacity: ccCard.stage >= 3 ? 1.0 : 0.0
                    transform: Translate {
                        y: ccCard.stage >= 3 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Text { x: 14; y: 10; text: "Sound"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.bold: true }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        y: 10
                        text: shellRoot.volumeMuted ? "Muted" : (shellRoot.volumeLevel + "%")
                        color: shellRoot.volumeMuted ? "#FF453A" : "#AEAEB2"
                        font.pixelSize: 11

                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.toggleMute()
                        }
                    }

                    Rectangle {
                        id: volTrack
                        x: 12; y: 32
                        width: 290
                        height: 24
                        radius: 12
                        color: ThemeTokens.inputBg
                        clip: true

                        Rectangle {
                            width: shellRoot.volumeMuted ? 24 : Math.max(24, 290 * (shellRoot.volumeLevel / 100))
                            height: 24
                            radius: 12
                            color: ThemeTokens.textPrimary
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
                            onPressed: (m) => shellRoot.setVolumePct((m.x / 290) * 100)
                            onPositionChanged: (m) => { if (pressed) shellRoot.setVolumePct((m.x / 290) * 100); }
                        }
                    }
                }

                // BARIS 4: NOW PLAYING MEDIA CARD (STAGE 4)
                Rectangle {
                    width: 314
                    height: 72
                    radius: 18
                    color: ThemeTokens.cardBg
                    border.width: 1
                    border.color: ThemeTokens.cardBg
                    opacity: ccCard.stage >= 4 ? 1.0 : 0.0
                    transform: Translate {
                        y: ccCard.stage >= 4 ? 0 : 12
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

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
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        x: 70; y: 37
                        width: 134
                        text: (overlay.mediaPlayer && overlay.mediaPlayer.trackArtist) ? overlay.mediaPlayer.trackArtist : "MPRIS Audio"
                        color: ThemeTokens.textSecondary
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Row {
                        x: 210; y: 21
                        spacing: 4

                        Rectangle {
                            width: 28; height: 30; radius: 15
                            color: ccPrevM.containsMouse ? "#33FFFFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Text { anchors.centerIn: parent; text: "|◀"; color: ThemeTokens.textPrimary; font.pixelSize: 10 }
                            MouseArea {
                                id: ccPrevM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: if (overlay.mediaPlayer) overlay.mediaPlayer.previous()
                            }
                        }

                        Rectangle {
                            width: 32; height: 30; radius: 15
                            color: ccPlayM.containsMouse ? "#33FFFFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Text {
                                anchors.centerIn: parent
                                text: (overlay.mediaPlayer && overlay.mediaPlayer.isPlaying) ? "❚❚" : "▶"
                                color: ThemeTokens.textPrimary
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
                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Text { anchors.centerIn: parent; text: "▶|"; color: ThemeTokens.textPrimary; font.pixelSize: 10 }
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
                        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 94
                        height: 38
                        radius: 13
                        color: ThemeTokens.cardBg
                        border.width: 1
                        border.color: ThemeTokens.cardBg

                        Text {
                            anchors.centerIn: parent
                            text: shellRoot.batteryPercent >= 0 ? ("BAT " + shellRoot.batteryPercent + "%") : "AC Power"
                            color: shellRoot.batteryStatus === "Charging" ? "#32D74B" : "#F5F5F7"
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
                        border.color: ThemeTokens.cardBg
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Text { anchors.centerIn: parent; text: "Atur Widget"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.bold: true }

                        MouseArea {
                            id: ccEditM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                shellRoot.closePopups();
                                hostWin.posY = hostWin.resolvedY;
                                hostWin.editMode = true;
                            }
                        }
                    }

                    Rectangle {
                        width: 66
                        height: 38
                        radius: 13
                        color: ccSetM.containsMouse ? "#38FFFFFF" : "#22FFFFFF"
                        border.width: 1
                        border.color: ThemeTokens.cardBg
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Text { anchors.centerIn: parent; text: "Settings"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.bold: true }

                        MouseArea {
                            id: ccSetM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onPressed: shellRoot.switchPopup("settings")
                        }
                    }

                    Rectangle {
                        width: 52
                        height: 38
                        radius: 13
                        color: ccLockM.containsMouse ? "#38FFFFFF" : "#22FFFFFF"
                        border.width: 1
                        border.color: ThemeTokens.cardBg
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Text { anchors.centerIn: parent; text: "Lock"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.bold: true }

                        MouseArea {
                            id: ccLockM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                shellRoot.closePopups();
                                shellRoot.runCmd("swaylock -f -c 000000 || loginctl lock-session");
                            }
                        }
                    }
                }
            }
        }

            // Sub-pilihan cepat Capture & Pengaturan Rekam Layar (Audio + Resolusi) — Topmost Z-Layer
            Rectangle {
                id: ccCaptureMenu
                visible: false
                z: 250
                anchors.right: parent.right
                anchors.rightMargin: 14
                y: Math.min(232, Math.max(12, parent.height - height - 12))
                width: 226
                height: ccCapCol.implicitHeight + 16
                radius: 15
                color: ThemeTokens.isDark ? "#F51A1C24" : "#F8FFFFFF"
                border.width: 1
                border.color: ThemeTokens.borderStrong

                // Penahan klik agar tidak tembus ke slider Display/Sound di bawahnya
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {}
                }

                Column {
                    id: ccCapCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 5

                    Repeater {
                        model: [
                            { id: "area", label: "Screenshot Area" },
                            { id: "full", label: "Layar Penuh" },
                            { id: "rec",  label: "Mulai Rekam (MP4)" }
                        ]
                        Rectangle {
                            width: ccCapCol.width
                            height: 27
                            radius: 8
                            color: capOptM.containsMouse ? (modelData.id === "rec" ? "#28FF453A" : ThemeTokens.accentSoft) : "transparent"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 9
                                text: modelData.label
                                color: modelData.id === "rec" ? ThemeTokens.danger : ThemeTokens.textPrimary
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 9
                                visible: modelData.id === "rec"
                                text: (ShellState.recResolution === "native" ? "Asli" : (ShellState.recResolution === "1440" ? "2K" : (ShellState.recResolution === "2160" ? "4K" : ShellState.recResolution + "p")))
                                color: ThemeTokens.textSecondary
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: capOptM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ccCaptureMenu.visible = false;
                                    shellRoot.closePopups();
                                    if (modelData.id === "area") screenshotDelayTimer.restart();
                                    else if (modelData.id === "full") shellRoot.captureFullscreen();
                                    else shellRoot.toggleScreenRecord();
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: ccCapCol.width
                        height: 1
                        color: ThemeTokens.dividerColor
                    }

                    Text {
                        text: "Sumber Audio Rekam"
                        color: ThemeTokens.textSecondary
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        leftPadding: 4
                    }

                    Row {
                        width: ccCapCol.width
                        spacing: 4
                        Repeater {
                            model: [
                                { id: "none",    label: "Mati" },
                                { id: "system",  label: "Sistem" },
                                { id: "sys_mic", label: "Sis + Mic" }
                            ]
                            Rectangle {
                                width: (ccCapCol.width - 8) / 3
                                height: 24
                                radius: 7
                                property bool active: ShellState.recAudioMode === modelData.id
                                color: active ? ThemeTokens.accent : ThemeTokens.inputBg
                                border.width: 1
                                border.color: active ? ThemeTokens.accent : ThemeTokens.borderSubtle
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: active ? "#FFFFFF" : ThemeTokens.textPrimary
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ShellState.recAudioMode = modelData.id
                                }
                            }
                        }
                    }

                    Text {
                        text: "Resolusi Video"
                        color: ThemeTokens.textSecondary
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        leftPadding: 4
                    }

                    Grid {
                        width: ccCapCol.width
                        columns: 3
                        spacing: 4
                        Repeater {
                            model: [
                                { id: "native", label: "Asli" },
                                { id: "360",    label: "360p" },
                                { id: "720",    label: "720p" },
                                { id: "1080",   label: "1080p" },
                                { id: "1440",   label: "2K" },
                                { id: "2160",   label: "4K" }
                            ]
                            Rectangle {
                                width: (ccCapCol.width - 8) / 3
                                height: 24
                                radius: 7
                                property bool active: ShellState.recResolution === modelData.id
                                color: active ? ThemeTokens.accent : ThemeTokens.inputBg
                                border.width: 1
                                border.color: active ? ThemeTokens.accent : ThemeTokens.borderSubtle
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: active ? "#FFFFFF" : ThemeTokens.textPrimary
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ShellState.recResolution = modelData.id
                                }
                            }
                        }
                    }
                }
            }

}
