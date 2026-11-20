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
            id: wWeather
            x: win.getWidgetX("weather")
            y: win.getWidgetY("weather")
            width: 148
            height: 136
            scale: win.widgetScale
            transformOrigin: Item.TopLeft
            visible: win.isWidgetOn("weather")
            opacity: root.bootStage >= 4 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

            Canvas {
                anchors.fill: parent
                property real dX: wWeather.x
                property real dY: wWeather.y
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
                onPaint: win.drawWidgetGlass(getContext("2d"), width, height, 24, wWeather.x, wWeather.y, false)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                Text {
                    text: root.weatherCity
                    color: "#D1D1D6"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: root.weatherTemp
                    color: "#FFFFFF"
                    font.pixelSize: 34
                    font.weight: Font.Light
                }
                Item { Layout.fillHeight: true }
                Text { text: root.weatherIcon; font.pixelSize: 15 }
                Text {
                    text: root.weatherDesc
                    color: "#E5E5EA"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: !win.editMode
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refreshWeather()
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
                onPressed: (m) => { let p = mapToItem(win.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wWeather.x; oy = wWeather.y; }
                onPositionChanged: (m) => { if (pressed) { let p = mapToItem(win.contentItem, m.x, m.y); win.setWidgetPos("weather", ox + (p.x - sx), oy + (p.y - sy)); } }
                onReleased: win.saveLayout()
            }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
                z: 25; width: 22; height: 22; radius: 11
                color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
                visible: win.editMode
                Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.setWidgetEnabled("weather", false) }
            }
        }
}
