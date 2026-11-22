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
            id: wWeather
            x: hostWin.getWidgetX("weather")
            y: hostWin.getWidgetY("weather")
            width: 148
            height: 136
            scale: hostWin.getWidgetScale("weather")
            transformOrigin: Item.TopLeft
        Behavior on x { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: !resizeArea.pressed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            visible: hostWin.isWidgetOn("weather")
            opacity: shellRoot.bootStage >= 4 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

            Canvas {
                anchors.fill: parent
                property real dX: wWeather.x
                property real dY: wWeather.y
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
                onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 24, wWeather.x, wWeather.y, false)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                Text {
                    text: shellRoot.weatherCity
                    color: "#D1D1D6"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: shellRoot.weatherTemp
                    color: ThemeTokens.textPrimary
                    font.pixelSize: 34
                    font.weight: Font.Light
                }
                Item { Layout.fillHeight: true }
                Text { text: shellRoot.weatherIcon; font.pixelSize: 15 }
                Text {
                    text: shellRoot.weatherDesc
                    color: ThemeTokens.textPrimary
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: !hostWin.editMode
                cursorShape: Qt.PointingHandCursor
                onClicked: shellRoot.refreshWeather()
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
                onPressed: (m) => { hostWin.bringWidgetToFront("weather"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wWeather.x; oy = wWeather.y; }
                onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("weather", ox + (p.x - sx), oy + (p.y - sy)); } }
                onReleased: hostWin.saveLayout()
            }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
                z: 25; width: 22; height: 22; radius: 11
                color: "#FF453A"; border.width: 1; border.color: ThemeTokens.textPrimary
                visible: hostWin.editMode
                Text { anchors.centerIn: parent; text: "×"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("weather", false) }
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
                        startScale = hostWin.getWidgetScale("weather");
                    }
                    onPositionChanged: (m) => {
                        if (pressed) {
                            let p = mapToItem(hostWin.contentItem, m.x, m.y);
                            let delta = (p.x - startX) / 226.0;
                            hostWin.setWidgetScale("weather", startScale + delta);
                        }
                    }
                    onReleased: hostWin.saveLayout()
                }
            }
        }
}
