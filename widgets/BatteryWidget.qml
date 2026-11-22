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
    required property var shellRoot
    required property var hostWin

        Item {
            id: wBattery
            x: hostWin.getWidgetX("battery")
            y: hostWin.getWidgetY("battery")
            width: 226
            height: 116
            scale: hostWin.getWidgetScale("battery")
            transformOrigin: Item.TopLeft
        Behavior on x { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: !resizeArea.pressed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            property bool _wActive: hostWin.isWidgetOn("battery")
        opacity: _wActive ? 1.0 : 0.0
        scale: (_wActive ? 1.0 : 0.92) * hostWin.widgetScale
        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        visible: _wActive || opacity > 0.01

            Canvas {
                anchors.fill: parent
                property real dX: wBattery.x
                property real dY: wBattery.y
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
                property real dTh: shellRoot.activeGlassDetail
                onDXChanged: requestPaint()
                onDYChanged: requestPaint()
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 24, wBattery.x, wBattery.y, false)
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                // Cincin Baterai Laptop
                Item {
                    width: 68; height: 68
                    Canvas {
                        anchors.fill: parent
                        property int pct: shellRoot.batteryPercent >= 0 ? shellRoot.batteryPercent : 100
                        property string st: shellRoot.batteryStatus
                        onPctChanged: requestPaint()
                        onStChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            let cx = width / 2, cy = height / 2, r = 28;
                            ctx.strokeStyle = "rgba(255,255,255,0.18)";
                            ctx.lineWidth = 6;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, Math.PI * 2);
                            ctx.stroke();

                            let frac = Math.max(0.02, Math.min(1.0, pct / 100));
                            ctx.strokeStyle = st === "Charging" ? "#32D74B" : (pct <= 20 ? "#FF453A" : "#30D158");
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + frac * Math.PI * 2);
                            ctx.stroke();
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: shellRoot.batteryPercent >= 0 ? (shellRoot.batteryPercent + "%") : "AC"
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: "ThinkPad L14"
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        text: shellRoot.batteryStatus === "Charging" ? "⚡ Sedang Mengisi" : "Daya Baterai"
                        color: "#32D74B"
                        font.pixelSize: 11
                    }
                    Text {
                        text: shellRoot.btDeviceName !== "" ? ("ᛒ " + shellRoot.btDeviceName) : "ᛒ Bluetooth Standby"
                        color: ThemeTokens.textSecondary
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 1
                acceptedButtons: Qt.RightButton
                onClicked: (m) => {
                    let p = mapToItem(hostWin.contentItem, m.x, m.y);
                    hostWin.openWidgetCtxMenu(p.x, p.y);
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 20
                visible: hostWin.editMode && !hostWin.widgetsLocked
                id: dragArea
            cursorShape: Qt.SizeAllCursor
                property real sx: 0; property real sy: 0; property real ox: 0; property real oy: 0
                onPressed: (m) => { hostWin.bringWidgetToFront("battery"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wBattery.x; oy = wBattery.y; }
                onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("battery", ox + (p.x - sx), oy + (p.y - sy)); } }
                onReleased: hostWin.saveLayout()
            }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
                z: 25; width: 22; height: 22; radius: 11
                color: "#FF453A"; border.width: 1; border.color: ThemeTokens.textPrimary
                visible: hostWin.editMode
                Text { anchors.centerIn: parent; text: "×"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("battery", false) }
            }

            // Handle Ubah Ukuran Bebas (Sudut Kanan Bawah)
            Rectangle {
                anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: -5
                z: 26; width: 20; height: 20; radius: 10
                color: ThemeTokens.accent; border.width: 1.5; border.color: "#FFFFFF"
                visible: hostWin.editMode && !hostWin.widgetsLocked
                Text { anchors.centerIn: parent; text: "◢"; color: "#FFFFFF"; font.pixelSize: 9 }
                MouseArea {
                    anchors.fill: parent
                    id: resizeArea
                cursorShape: Qt.SizeFDiagCursor
                    property real startX: 0
                    property real startScale: 1.0
                    onPressed: (m) => {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        startX = p.x;
                        startScale = hostWin.getWidgetScale("battery");
                    }
                    onPositionChanged: (m) => {
                        if (pressed) {
                            let p = mapToItem(hostWin.contentItem, m.x, m.y);
                            let delta = (p.x - startX) / 226.0;
                            hostWin.setWidgetScale("battery", startScale + delta);
                        }
                    }
                    onReleased: hostWin.saveLayout()
                }
            }
        }
}
