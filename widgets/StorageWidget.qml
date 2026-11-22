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
        id: wStorage
        x: hostWin.getWidgetX("storage")
        y: hostWin.getWidgetY("storage")
        width: 226
        height: 92
        readonly property bool isOn: hostWin.isWidgetOn("storage")
        readonly property real baseScale: hostWin.getWidgetScale("storage")
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
            property real dX: wStorage.x
            property real dY: wStorage.y
            property real dS: wStorage.scale
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
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 22, wStorage.x, wStorage.y, false)
        }

        property string diskUsed: "42 GB"
        property string diskTotal: "256 GB"
        property int diskPct: 18

        Process {
            id: dfProc
            running: wStorage.visible
            command: ["sh", "-c", "df -h / | awk 'NR==2 {print $3"|"$2"|"$5}'"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let p = text.trim().split("|");
                    if (p.length >= 3) {
                        wStorage.diskUsed = p[0];
                        wStorage.diskTotal = p[1];
                        wStorage.diskPct = parseInt(p[2].replace("%", "")) || 0;
                    }
                }
            }
        }
        Timer { interval: 30000; running: wStorage.visible; repeat: true; onTriggered: dfProc.running = true }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 6
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Storage (/)"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                Item { Layout.fillWidth: true }
                Text { text: wStorage.diskPct + "%"; color: ThemeTokens.accent; font.pixelSize: 11; font.bold: true }
            }
            Rectangle {
                Layout.fillWidth: true; height: 7; radius: 3.5; color: ThemeTokens.inputBg
                Rectangle {
                    width: parent.width * (wStorage.diskPct / 100.0)
                    height: 7; radius: 3.5; color: ThemeTokens.accent
                }
            }
            Text {
                text: wStorage.diskUsed + " terpakai dari " + wStorage.diskTotal
                color: ThemeTokens.textSecondary; font.pixelSize: 10
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

        // Drag Posisi
        MouseArea {
            anchors.fill: parent
            z: 20
            visible: hostWin.editMode && !hostWin.widgetsLocked
            id: dragArea
            cursorShape: Qt.SizeAllCursor
            property real sx: 0; property real sy: 0; property real ox: 0; property real oy: 0
            onPressed: (m) => { hostWin.bringWidgetToFront("storage"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wStorage.x; oy = wStorage.y; }
            onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("storage", ox + (p.x - sx), oy + (p.y - sy)); } }
            onReleased: hostWin.saveLayout()
        }

        // Tombol Hapus (X)
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
            z: 25; width: 22; height: 22; radius: 11
            color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
            visible: hostWin.editMode
            Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("storage", false) }
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
                    startScale = hostWin.getWidgetScale("storage");
                }
                onPositionChanged: (m) => {
                    if (pressed) {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        let delta = (p.x - startX) / 226.0;
                        hostWin.setWidgetScale("storage", startScale + delta);
                    }
                }
                onReleased: hostWin.saveLayout()
            }
        }
    }
}
