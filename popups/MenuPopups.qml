import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
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
    readonly property bool anyVisible: (appleCard.opacity > 0.01 || winCard.opacity > 0.01 || deskCard.opacity > 0.01 || powerConfirmOverlay.opacity > 0.01 || powerBlackoutOverlay.opacity > 0.01 || phoneScreenOffOverlay.opacity > 0.01 || modRoot.powerConfirmClosingForCancel || modRoot.powerConfirmClosingForExec || modRoot.powerConfirmOpen || modRoot.powerExecuting || modRoot.screenOffActive)
    onAnyVisibleChanged: shellRoot.menuModalActive = anyVisible
    Component.onCompleted: shellRoot.menuModalActive = anyVisible
    Component.onDestruction: shellRoot.menuModalActive = false

    property string pendingPowerCmd: ""
    property string pendingPowerLabel: ""
    property bool powerConfirmOpen: (pendingPowerCmd !== "")
    property bool powerConfirmClosingForExec: false
    property bool powerConfirmClosingForCancel: false
    property bool powerExecuting: false
    property string activePowerCmd: ""
    property string activePowerLabel: ""
    property bool screenOffActive: false
    property string screenOffMode: "lock"
    property string screenOffCmd: ""

    function triggerPhoneScreenOff(mode, cmd) {
        if (modRoot.screenOffActive) return;
        modRoot.screenOffMode = mode;
        modRoot.screenOffCmd = cmd;
        modRoot.screenOffActive = true;
        shellRoot.activePopup = "";
        phoneBeamAnim.restart();
        phoneScreenExecTimer.restart();
    }

        Rectangle {
            id: appleCard
            z: 10
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 4
            anchors.leftMargin: 10
            width: 220
            height: appleCol.implicitHeight + 12
            radius: 14
            color: "transparent"
            Canvas {
                anchors.fill: parent
                z: -1
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
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
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, parent.radius, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: "#38FFFFFF"
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "apple" || opacity > 0.01)



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "apple")
            property int stage: 0
            onIsOpenChanged: {
                if (isOpen) { stage = 0; appleStagger.restart(); }
                else { appleStagger.stop(); stage = 0; }
            }
            Timer {
                id: appleStagger
                interval: 34; repeat: true
                onTriggered: { if (appleCard.stage < 6) appleCard.stage++; else stop(); }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: appleCard.isOpen ? 0 : -8
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopLeft

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

            Column {
                id: appleCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                Repeater {
                    model: [
                        { label: "About This System", sep: false, action: "about", cmd: "" },
                        { label: "System Settings...", sep: true, action: "settings", cmd: "" },
                        { label: "Lock Screen", sep: false, action: "lock", cmd: "" },
                        { label: "Sleep", sep: true, action: "sleep", cmd: "sleep 0.25; systemctl suspend" },
                        { label: "Restart...", sep: false, action: "power", cmd: "systemctl reboot || loginctl reboot || gdbus call --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 --method org.freedesktop.login1.Manager.Reboot false" },
                        { label: "Shut Down...", sep: false, action: "power", cmd: "systemctl poweroff || loginctl poweroff || gdbus call --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 --method org.freedesktop.login1.Manager.PowerOff false" }
                    ]

                    Column {
                        width: appleCol.width
                        spacing: 2
                        opacity: appleCard.stage >= (index + 1) ? 1.0 : 0.0
                        transform: Translate {
                            y: appleCard.stage >= (index + 1) ? 0 : 6
                            Behavior on y { NumberAnimation { duration: 310; easing.type: Easing.OutQuint } }
                        }
                        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                        Rectangle {
                            width: appleCol.width
                            height: 28
                            radius: 7
                            color: mItem1.containsMouse ? "#0A84FF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 130 } }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: "#F5F5F7"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: mItem1
                                anchors.fill: parent
                                z: 5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    mouse.accepted = true;
                                    if (modelData.action === "about") {
                                        shellRoot.switchPopup("about");
                                    } else if (modelData.action === "settings") {
                                        shellRoot.switchPopup("settings");
                                    } else if (modelData.action === "lock" || modelData.action === "sleep") {
                                        modRoot.triggerPhoneScreenOff(modelData.action, modelData.cmd);
                                    } else if (modelData.action === "power") {
                                        modRoot.pendingPowerLabel = modelData.label;
                                        modRoot.pendingPowerCmd = modelData.cmd;
                                        shellRoot.activePopup = "";
                                    } else {
                                        shellRoot.closePopups();
                                        shellRoot.runCmd(modelData.cmd);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: appleCol.width - 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 1
                            color: "#22FFFFFF"
                            visible: modelData.sep
                        }
                    }
                }
            }
        }
        Rectangle {
            id: winCard
            z: 10
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 4
            anchors.leftMargin: 96
            width: 210
            height: winMenuCol.implicitHeight + 12
            radius: 14
            color: "transparent"
            Canvas {
                anchors.fill: parent
                z: -1
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
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
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, parent.radius, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: "#38FFFFFF"
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "window" || opacity > 0.01)



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "window")
            property int stage: 0
            onIsOpenChanged: {
                if (isOpen) { stage = 0; winStagger.restart(); }
                else { winStagger.stop(); stage = 0; }
            }
            Timer {
                id: winStagger
                interval: 34; repeat: true
                onTriggered: { if (winCard.stage < 4) winCard.stage++; else stop(); }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: winCard.isOpen ? 0 : -8
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopLeft

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

            Column {
                id: winMenuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                Repeater {
                    model: [
                        { label: "Toggle Overview", cmd: "niri msg action toggle-overview" },
                        { label: "Toggle Fullscreen", cmd: "niri msg action fullscreen-window" },
                        { label: "Center Focused Column", cmd: "niri msg action center-column" },
                        { label: "Close Focused Window", cmd: "niri msg action close-window" }
                    ]

                    Rectangle {
                        width: winMenuCol.width
                        height: 28
                        radius: 7
                        color: mItem2.containsMouse ? "#0A84FF" : "transparent"
                        opacity: winCard.stage >= (index + 1) ? 1.0 : 0.0
                        transform: Translate {
                            y: winCard.stage >= (index + 1) ? 0 : 6
                            Behavior on y { NumberAnimation { duration: 310; easing.type: Easing.OutQuint } }
                        }
                        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 130 } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: "#F5F5F7"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: mItem2
                            anchors.fill: parent
                            z: 5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                shellRoot.closePopups();
                                shellRoot.runCmd(modelData.cmd);
                            }
                        }
                    }
                }
            }
        }
        Rectangle {
            id: deskCard
            z: 10
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 4
            anchors.leftMargin: 162
            width: 220
            height: deskMenuCol.implicitHeight + 12
            radius: 14
            color: "transparent"
            Canvas {
                anchors.fill: parent
                z: -1
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
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
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, parent.radius, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: "#38FFFFFF"
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "desktop" || opacity > 0.01)



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "desktop")
            property int stage: 0
            onIsOpenChanged: {
                if (isOpen) { stage = 0; deskStagger.restart(); }
                else { deskStagger.stop(); stage = 0; }
            }
            Timer {
                id: deskStagger
                interval: 34; repeat: true
                onTriggered: { if (deskCard.stage < 4) deskCard.stage++; else stop(); }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: deskCard.isOpen ? 0 : -8
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopLeft

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

            Column {
                id: deskMenuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                Repeater {
                    model: [
                        { label: "Next Wallpaper (Shader)", action: "wp" },
                        { label: "Take Screenshot...", action: "ss" },
                        { label: "Atur Posisi & Ukuran Widget", action: "edit" },
                        { label: "Reset Layout Widget", action: "reset" }
                    ]

                    Rectangle {
                        width: deskMenuCol.width
                        height: 28
                        radius: 7
                        color: mItem3.containsMouse ? "#0A84FF" : "transparent"
                        opacity: deskCard.stage >= (index + 1) ? 1.0 : 0.0
                        transform: Translate {
                            y: deskCard.stage >= (index + 1) ? 0 : 6
                            Behavior on y { NumberAnimation { duration: 310; easing.type: Easing.OutQuint } }
                        }
                        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 130 } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: "#F5F5F7"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: mItem3
                            anchors.fill: parent
                            z: 5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                shellRoot.closePopups();
                                if (modelData.action === "wp") shellRoot.pickRandomWallpaper();
                                else if (modelData.action === "ss") screenshotDelayTimer.restart();
                                else if (modelData.action === "edit") { hostWin.editMode = true; }
                                else if (modelData.action === "reset") hostWin.resetLayout();
                            }
                        }
                    }
                }
            }
        }

    // ── Modal Konfirmasi Reboot / Shut Down dengan Latar Gelap, Blur, Spring Bertahap & Tombol Merah ──
    Item {
        id: powerConfirmOverlay
        anchors.fill: parent
        z: 90
        property bool shown: modRoot.powerConfirmOpen && !modRoot.powerConfirmClosingForExec && !modRoot.powerConfirmClosingForCancel && !modRoot.powerExecuting
        property int step: 0
        visible: shown || modRoot.powerConfirmClosingForExec || modRoot.powerConfirmClosingForCancel || opacity > 0.01
        opacity: shown ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        onShownChanged: {
            if (shown) {
                step = 0;
                powerStepTimer.restart();
            } else {
                powerStepTimer.stop();
                step = 0;
            }
        }

        Timer {
            id: powerStepTimer
            interval: 75
            repeat: true
            onTriggered: {
                if (powerConfirmOverlay.step < 2) powerConfirmOverlay.step++;
                else stop();
            }
        }

        Timer {
            id: confirmCancelReverseTimer
            interval: 240
            repeat: false
            onTriggered: {
                modRoot.powerConfirmClosingForCancel = false;
                modRoot.pendingPowerCmd = "";
                modRoot.pendingPowerLabel = "";
            }
        }

        Timer {
            id: confirmToBlackoutTimer
            interval: 240
            repeat: false
            onTriggered: {
                modRoot.powerExecuting = true;
                powerExecTimer.restart();
                modRoot.powerConfirmClosingForExec = false;
                modRoot.pendingPowerCmd = "";
                modRoot.pendingPowerLabel = "";
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#99000000"
        }

        ShaderEffectSource {
            id: bgBlurSource
            anchors.fill: parent
            sourceItem: null
            sourceRect: Qt.rect(0, 0, width, height)
            visible: false
            live: powerConfirmOverlay.visible
            hideSource: false
        }

        MultiEffect {
            anchors.fill: parent
            source: bgBlurSource
            blurEnabled: false
            blur: 0.72
            blurMax: 32
            opacity: powerConfirmOverlay.shown ? 0.9 : 0.0
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            z: 1
            preventStealing: true
            onClicked: {
                if (!modRoot.powerConfirmClosingForCancel && !modRoot.powerConfirmClosingForExec && modRoot.powerConfirmOpen) {
                    modRoot.powerConfirmClosingForCancel = true;
                    confirmCancelReverseTimer.restart();
                }
            }
        }

        Rectangle {
            id: powerConfirmCard
            z: 5
            width: 344
            height: 182
            radius: 20
            anchors.centerIn: parent
            color: "transparent"
            border.width: 1
            border.color: "#44FFFFFF"

            opacity: powerConfirmOverlay.shown ? 1.0 : 0.0
            scale: powerConfirmOverlay.shown ? 1.0 : 0.78
            transform: Translate {
                y: powerConfirmOverlay.shown ? 0 : 22
                Behavior on y { SpringAnimation { mass: 1.05; spring: 3.4; damping: 0.42; epsilon: 0.001 } }
            }
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 3.4; damping: 0.42; epsilon: 0.001 } }

            Canvas {
                anchors.fill: parent
                z: -1
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
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
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, parent.radius, pos.x, pos.y, sw, sh, false, false);
                }
            }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    opacity: powerConfirmOverlay.step >= 1 ? 1.0 : 0.0
                    transform: Translate {
                        y: powerConfirmOverlay.step >= 1 ? 0 : 10
                        Behavior on y { SpringAnimation { mass: 0.95; spring: 3.6; damping: 0.45; epsilon: 0.001 } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Konfirmasi " + (modRoot.pendingPowerLabel || "Tindakan").replace("...", "")
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "Apakah kamu yakin ingin melanjutkan " + (modRoot.pendingPowerLabel || "perintah ini").replace("...", "").toLowerCase() + "?"
                        color: "#E5E5EA"
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 14
                    opacity: powerConfirmOverlay.step >= 2 ? 1.0 : 0.0
                    scale: powerConfirmOverlay.step >= 2 ? 1.0 : 0.86
                    transform: Translate {
                        y: powerConfirmOverlay.step >= 2 ? 0 : 12
                        Behavior on y { SpringAnimation { mass: 0.95; spring: 3.5; damping: 0.44; epsilon: 0.001 } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { mass: 0.95; spring: 3.5; damping: 0.44; epsilon: 0.001 } }

                    Rectangle {
                        width: 112
                        height: 38
                        radius: 11
                        color: okBtnArea.pressed ? "#B71C1C" : (okBtnArea.containsMouse ? "#FF3B30" : "#D32F2F")
                        scale: okBtnArea.pressed ? 0.90 : (okBtnArea.containsMouse ? 1.06 : 1.0)
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on scale { SpringAnimation { mass: 0.9; spring: 3.8; damping: 0.43; epsilon: 0.001 } }

                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: "#FFFFFF"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        MouseArea {
                            id: okBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                let cmd = modRoot.pendingPowerCmd;
                                let lbl = modRoot.pendingPowerLabel;
                                if (cmd && cmd !== "" && !modRoot.powerConfirmClosingForExec) {
                                    modRoot.activePowerCmd = cmd;
                                    modRoot.activePowerLabel = lbl;
                                    modRoot.powerConfirmClosingForExec = true;
                                    confirmToBlackoutTimer.restart();
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 112
                        height: 38
                        radius: 11
                        color: noBtnArea.pressed ? "#9A0007" : (noBtnArea.containsMouse ? "#EF5350" : "#C62828")
                        scale: noBtnArea.pressed ? 0.90 : (noBtnArea.containsMouse ? 1.06 : 1.0)
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on scale { SpringAnimation { mass: 0.9; spring: 3.8; damping: 0.43; epsilon: 0.001 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Tidak"
                            color: "#FFFFFF"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        MouseArea {
                            id: noBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                if (!modRoot.powerConfirmClosingForCancel && !modRoot.powerConfirmClosingForExec && modRoot.powerConfirmOpen) {
                                    modRoot.powerConfirmClosingForCancel = true;
                                    confirmCancelReverseTimer.restart();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Transisi Layar Menghitam + Logo Berputar 2 Detik Lalu Eksekusi ──
    Item {
        id: powerBlackoutOverlay
        anchors.fill: parent
        z: 120
        visible: modRoot.powerExecuting || opacity > 0.01
        opacity: modRoot.powerExecuting ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }

        Rectangle {
            anchors.fill: parent
            color: "#FF000000"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
        }

        Column {
            anchors.centerIn: parent
            spacing: 14
            scale: modRoot.powerExecuting ? 1.0 : 0.78
            transform: Translate {
                y: modRoot.powerExecuting ? 0 : 14
                Behavior on y { SpringAnimation { mass: 1.0; spring: 3.4; damping: 0.42; epsilon: 0.001 } }
            }
            Behavior on scale { SpringAnimation { mass: 1.0; spring: 3.4; damping: 0.42; epsilon: 0.001 } }

            Item {
                id: spinnerWrap
                width: 64
                height: 64
                anchors.horizontalCenter: parent.horizontalCenter

                Canvas {
                    id: powerCircleSpinner
                    anchors.centerIn: parent
                    width: 56
                    height: 56
                    antialiasing: true
                    smooth: true

                    property real arcSpan: 105
                    onArcSpanChanged: requestPaint()
                    Component.onCompleted: requestPaint()

                    Connections {
                        target: modRoot
                        function onPowerExecutingChanged() {
                            if (modRoot.powerExecuting) powerCircleSpinner.requestPaint();
                        }
                    }

                    SequentialAnimation on arcSpan {
                        running: modRoot.powerExecuting
                        loops: Animation.Infinite
                        NumberAnimation { from: 82; to: 148; duration: 760; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 148; to: 82; duration: 760; easing.type: Easing.InOutSine }
                    }

                    RotationAnimation on rotation {
                        running: modRoot.powerExecuting
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 920
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width * 0.5;
                        var cy = height * 0.5;
                        var lw = 6.2;
                        var r = (Math.min(width, height) - lw) * 0.5;

                        // Track cincin lingkaran putih transparan
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2, false);
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.18)";
                        ctx.lineWidth = lw;
                        ctx.stroke();

                        // Busur lingkaran putih berujung membulat
                        var startRad = -Math.PI * 0.5;
                        var endRad = startRad + (arcSpan * Math.PI / 180.0);
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, startRad, endRad, false);
                        ctx.strokeStyle = "#FFFFFF";
                        ctx.lineWidth = lw;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (modRoot.activePowerLabel || "Memproses").replace("...", "") + "..."
                color: "#F5F5F7"
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }

        Timer {
            id: powerFallbackResetTimer
            interval: 4000
            repeat: false
            onTriggered: {
                modRoot.powerExecuting = false;
            }
        }

        Process {
            id: powerActionProc
        }

        Timer {
            id: powerExecTimer
            interval: 2000
            repeat: false
            onTriggered: {
                let cmd = modRoot.activePowerCmd;
                modRoot.activePowerCmd = "";
                modRoot.activePowerLabel = "";
                if (cmd && cmd !== "") {
                    powerActionProc.command = ["sh", "-c", cmd + " >/tmp/power_action.log 2>&1"];
                    powerActionProc.startDetached();
                }
                powerFallbackResetTimer.restart();
            }
        }
    }


    // ── Animasi Layar Mati ala HP untuk Lock Screen & Sleep ──
    Item {
        id: phoneScreenOffOverlay
        anchors.fill: parent
        z: 130
        visible: modRoot.screenOffActive || opacity > 0.01
        opacity: modRoot.screenOffActive ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }

        property real beamScaleY: 1.0
        property real beamScaleX: 1.0
        property real beamOpacity: 0.0

        SequentialAnimation {
            id: phoneBeamAnim
            running: false

            PropertyAction { target: phoneScreenOffOverlay; property: "beamScaleY"; value: 1.0 }
            PropertyAction { target: phoneScreenOffOverlay; property: "beamScaleX"; value: 1.0 }
            PropertyAction { target: phoneScreenOffOverlay; property: "beamOpacity"; value: 0.45 }

            ParallelAnimation {
                NumberAnimation {
                    target: phoneScreenOffOverlay
                    property: "beamScaleY"
                    from: 1.0
                    to: 0.004
                    duration: 230
                    easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    target: phoneScreenOffOverlay
                    property: "beamOpacity"
                    from: 0.45
                    to: 0.95
                    duration: 190
                    easing.type: Easing.OutQuad
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: phoneScreenOffOverlay
                    property: "beamScaleX"
                    from: 1.0
                    to: 0.0
                    duration: 180
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: phoneScreenOffOverlay
                    property: "beamOpacity"
                    from: 0.95
                    to: 0.0
                    duration: 180
                    easing.type: Easing.InQuad
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#FF000000"
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: "#E8F4FF"
            opacity: phoneScreenOffOverlay.beamOpacity
            transform: Scale {
                origin.x: phoneScreenOffOverlay.width * 0.5
                origin.y: phoneScreenOffOverlay.height * 0.5
                xScale: phoneScreenOffOverlay.beamScaleX
                yScale: phoneScreenOffOverlay.beamScaleY
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 10
            opacity: modRoot.screenOffActive ? 1.0 : 0.0
            scale: modRoot.screenOffActive ? 1.0 : 0.78
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 58
                height: 58
                radius: 29
                color: "#1EFFFFFF"
                border.width: 1
                border.color: "#3CFFFFFF"

                Text {
                    anchors.centerIn: parent
                    text: modRoot.screenOffMode === "sleep" ? "☾" : "🔒"
                    color: modRoot.screenOffMode === "sleep" ? "#BF5AF2" : "#64D2FF"
                    font.pixelSize: 24
                    font.bold: true
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modRoot.screenOffMode === "sleep" ? "Sleep..." : "Screen Locked"
                color: "#E5E5EA"
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
        }

        Timer {
            id: phoneScreenExecTimer
            interval: 750
            repeat: false
            onTriggered: {
                shellRoot.sessionLocked = true;
                let cmd = modRoot.screenOffCmd;
                if (cmd && cmd !== "") {
                    shellRoot.runCmd(cmd);
                }
                phoneScreenWakeTimer.restart();
            }
        }

        Timer {
            id: phoneScreenWakeTimer
            interval: 550
            repeat: false
            onTriggered: {
                modRoot.screenOffActive = false;
                modRoot.screenOffCmd = "";
            }
        }
    }
}
