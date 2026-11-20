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
            id: wSysmon
            x: hostWin.getWidgetX("sysmon")
            y: hostWin.getWidgetY("sysmon")
            width: 226
            height: 116
            scale: hostWin.widgetScale
            transformOrigin: Item.TopLeft
            visible: hostWin.isWidgetOn("sysmon")

            Canvas {
                anchors.fill: parent
                property real dX: wSysmon.x
                property real dY: wSysmon.y
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
                onDXChanged: requestPaint()
                onDYChanged: requestPaint()
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 24, wSysmon.x, wSysmon.y, false)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "System Activity"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Text { text: shellRoot.cpuTempC + "°C"; color: shellRoot.cpuTempC > 75 ? "#FF453A" : "#64D2FF"; font.pixelSize: 11; font.bold: true }
                }

                // CPU Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU Ryzen 5"; color: "#D1D1D6"; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: shellRoot.cpuUsagePct + "%"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 5; radius: 2.5; color: "#28FFFFFF"
                        Rectangle {
                            width: parent.width * (shellRoot.cpuUsagePct / 100)
                            height: 5; radius: 2.5; color: "#0A84FF"
                            Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // RAM Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Memory"; color: "#D1D1D6"; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: shellRoot.ramUsageText; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 5; radius: 2.5; color: "#28FFFFFF"
                        Rectangle {
                            width: parent.width * (shellRoot.ramUsagePct / 100)
                            height: 5; radius: 2.5; color: "#BF5AF2"
                            Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 18
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
                cursorShape: Qt.SizeAllCursor
                property real sx: 0; property real sy: 0; property real ox: 0; property real oy: 0
                onPressed: (m) => { let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wSysmon.x; oy = wSysmon.y; }
                onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("sysmon", ox + (p.x - sx), oy + (p.y - sy)); } }
                onReleased: hostWin.saveLayout()
            }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
                z: 25; width: 22; height: 22; radius: 11
                color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
                visible: hostWin.editMode
                Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("sysmon", false) }
            }
        }
}
