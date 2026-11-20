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
    readonly property bool anyVisible: (appleCard.opacity > 0.01 || winCard.opacity > 0.01 || deskCard.opacity > 0.01)

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
                Behavior on y { SpringAnimation { mass: 1.15; spring: 4.2; damping: 0.84; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopLeft

            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
            Behavior on scale { SpringAnimation { mass: 1.15; spring: 4.2; damping: 0.84; epsilon: 0.001 } }

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
                        { label: "Lock Screen", sep: false, cmd: "swaylock -f -c 000000 || loginctl lock-session" },
                        { label: "Sleep", sep: true, cmd: "systemctl suspend" },
                        { label: "Restart...", sep: false, cmd: "systemctl reboot" },
                        { label: "Shut Down...", sep: false, cmd: "systemctl poweroff" }
                    ]

                    Column {
                        width: appleCol.width
                        spacing: 2
                        opacity: appleCard.stage >= (index + 1) ? 1.0 : 0.0
                        transform: Translate {
                            y: appleCard.stage >= (index + 1) ? 0 : 6
                            Behavior on y { NumberAnimation { duration: 310; easing.type: Easing.OutQuint } }
                        }
                        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }

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
                                onClicked: {
                                    if (modelData.action === "about") {
                                        shellRoot.switchPopup("about");
                                    } else if (modelData.action === "settings") {
                                        shellRoot.switchPopup("settings");
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
                Behavior on y { SpringAnimation { mass: 1.15; spring: 4.2; damping: 0.84; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopLeft

            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
            Behavior on scale { SpringAnimation { mass: 1.15; spring: 4.2; damping: 0.84; epsilon: 0.001 } }

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
                        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
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
                Behavior on y { SpringAnimation { mass: 1.15; spring: 4.2; damping: 0.84; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopLeft

            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
            Behavior on scale { SpringAnimation { mass: 1.15; spring: 4.2; damping: 0.84; epsilon: 0.001 } }

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
                        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
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
}
