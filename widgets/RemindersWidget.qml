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
        id: wReminders
        x: hostWin.getWidgetX("reminders")
        y: hostWin.getWidgetY("reminders")
        width: 226
        height: 148
        readonly property bool isOn: hostWin.isWidgetOn("reminders")
        readonly property real baseScale: hostWin.getWidgetScale("reminders")
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
            property real dX: wReminders.x
            property real dY: wReminders.y
            property real dS: wReminders.scale
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
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 24, wReminders.x, wReminders.y, false)
        }

        property var tasks: [
            { text: "Cek jadwal kuliah & lab", done: true },
            { text: "Push rilis NivrOS 1.0", done: false },
            { text: "Review konfigurasi Niri", done: false }
        ]

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 7; z: 19
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Reminders"; color: "#FF9F0A"; font.pixelSize: 13; font.bold: true }
                Item { Layout.fillWidth: true }
                Text {
                    text: wReminders.tasks.filter(t => !t.done).length + " sisa"
                    color: ThemeTokens.textSecondary; font.pixelSize: 10; font.bold: true
                }
            }

            Repeater {
                model: wReminders.tasks
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Rectangle {
                        width: 16; height: 16; radius: 8
                        color: modelData.done ? "#FF9F0A" : "transparent"
                        border.width: 1.5; border.color: modelData.done ? "#FF9F0A" : ThemeTokens.textSecondary
                        Text { anchors.centerIn: parent; text: "✓"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true; visible: modelData.done }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.text
                        color: modelData.done ? ThemeTokens.textMuted : ThemeTokens.textPrimary
                        font.pixelSize: 11
                        font.strikeout: modelData.done
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let arr = JSON.parse(JSON.stringify(wReminders.tasks));
                            arr[index].done = !arr[index].done;
                            wReminders.tasks = arr;
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
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
            onPressed: (m) => { hostWin.bringWidgetToFront("reminders"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wReminders.x; oy = wReminders.y; }
            onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("reminders", ox + (p.x - sx), oy + (p.y - sy)); } }
            onReleased: hostWin.saveLayout()
        }

        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
            z: 25; width: 22; height: 22; radius: 11
            color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
            visible: hostWin.editMode
            Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("reminders", false) }
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
                    startScale = hostWin.getWidgetScale("reminders");
                }
                onPositionChanged: (m) => {
                    if (pressed) {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        let delta = (p.x - startX) / 226.0;
                        hostWin.setWidgetScale("reminders", startScale + delta);
                    }
                }
                onReleased: hostWin.saveLayout()
            }
        }
    }
}
