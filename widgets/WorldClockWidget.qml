import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

Item {
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin

    Item {
        id: wWorldClock
        x: hostWin.getWidgetX("worldclock")
        y: hostWin.getWidgetY("worldclock")
        width: 226
        height: 166
        readonly property bool isOn: hostWin.isWidgetOn("worldclock")
        readonly property real baseScale: hostWin.getWidgetScale("worldclock")
        property bool entered: false
        Component.onCompleted: entered = true
        opacity: (isOn && entered) ? 1.0 : 0.0
        scale: (isOn && entered) ? baseScale : (baseScale * 0.86)
        visible: opacity > 0.01
        transformOrigin: Item.TopLeft
        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on x { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: !resizeArea.pressed; NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

        Canvas {
            anchors.fill: parent
            property real dX: wWorldClock.x
            property real dY: wWorldClock.y
            property real dS: wWorldClock.scale
            property real dO: shellRoot.aeroOpacity
            property real dR: shellRoot.aeroReflection
            property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
            property real dTh: shellRoot.activeGlassDetail
            onDXChanged: requestPaint()
            onDYChanged: requestPaint()
            onDSChanged: requestPaint()
            onDOChanged: requestPaint()
            onDRChanged: requestPaint()
            onDStChanged: requestPaint()
            onDThChanged: requestPaint()
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 24, wWorldClock.x, wWorldClock.y, false)
        }

        property date now: new Date()
        Timer { interval: 10000; running: wWorldClock.visible; repeat: true; onTriggered: wWorldClock.now = new Date() }

        function cityTime(offsetHours) {
            let utc = now.getTime() + (now.getTimezoneOffset() * 60000);
            let d = new Date(utc + (3600000 * offsetHours));
            return String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0");
        }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 8
            Text { text: "WORLD CLOCK"; color: ThemeTokens.accent; font.pixelSize: 9; font.bold: true }

            Repeater {
                model: [
                    { city: "Jakarta",  sub: "WIB • Hari Ini", off: 7 },
                    { city: "Tokyo",    sub: "JST • +2 Jam",   off: 9 },
                    { city: "London",   sub: "GMT • -7 Jam",   off: 0 }
                ]
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: modelData.city; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                        Text { text: modelData.sub; color: ThemeTokens.textSecondary; font.pixelSize: 9 }
                    }
                    Text {
                        text: wWorldClock.cityTime(modelData.off)
                        color: ThemeTokens.textPrimary; font.pixelSize: 16; font.bold: true
                    }
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
            onPressed: (m) => { hostWin.bringWidgetToFront("worldclock"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wWorldClock.x; oy = wWorldClock.y; }
            onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("worldclock", ox + (p.x - sx), oy + (p.y - sy)); } }
            onReleased: hostWin.saveLayout()
        }

        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
            z: 25; width: 22; height: 22; radius: 11
            color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
            visible: hostWin.editMode
            Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("worldclock", false) }
        }

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
                    startScale = hostWin.getWidgetScale("worldclock");
                }
                onPositionChanged: (m) => {
                    if (pressed) {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        let delta = (p.x - startX) / 226.0;
                        hostWin.setWidgetScale("worldclock", startScale + delta);
                    }
                }
                onReleased: hostWin.saveLayout()
            }
        }
    }
}
