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

        Item {
            id: wBattery
            x: win.getWidgetX("battery")
            y: win.getWidgetY("battery")
            width: 226
            height: 116
            scale: win.widgetScale
            transformOrigin: Item.TopLeft
            visible: win.isWidgetOn("battery")

            Canvas {
                anchors.fill: parent
                property real dX: wBattery.x
                property real dY: wBattery.y
                property real dO: root.aeroOpacity
                property real dR: root.aeroReflection
                property string dSt: root.glassStyle
                property real dTh: root.activeGlassDetail
                onDXChanged: requestPaint()
                onDYChanged: requestPaint()
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: win.drawWidgetGlass(getContext("2d"), width, height, 24, wBattery.x, wBattery.y, false)
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
                        property int pct: root.batteryPercent >= 0 ? root.batteryPercent : 100
                        property string st: root.batteryStatus
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
                        text: root.batteryPercent >= 0 ? (root.batteryPercent + "%") : "AC"
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: "ThinkPad L14"
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        text: root.batteryStatus === "Charging" ? "⚡ Sedang Mengisi" : "Daya Baterai"
                        color: "#32D74B"
                        font.pixelSize: 11
                    }
                    Text {
                        text: root.btDeviceName !== "" ? ("ᛒ " + root.btDeviceName) : "ᛒ Bluetooth Standby"
                        color: "#C7C7CC"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 18
                acceptedButtons: Qt.RightButton
                onClicked: (m) => {
                    let p = mapToItem(win.contentItem, m.x, m.y);
                    win.openWidgetCtxMenu(p.x, p.y);
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 20
                visible: win.editMode && !win.widgetsLocked
                cursorShape: Qt.SizeAllCursor
                property real sx: 0; property real sy: 0; property real ox: 0; property real oy: 0
                onPressed: (m) => { let p = mapToItem(win.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wBattery.x; oy = wBattery.y; }
                onPositionChanged: (m) => { if (pressed) { let p = mapToItem(win.contentItem, m.x, m.y); win.setWidgetPos("battery", ox + (p.x - sx), oy + (p.y - sy)); } }
                onReleased: win.saveLayout()
            }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
                z: 25; width: 22; height: 22; radius: 11
                color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
                visible: win.editMode
                Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.setWidgetEnabled("battery", false) }
            }
        }
}
