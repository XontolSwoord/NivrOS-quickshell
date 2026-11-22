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
        id: wNetwork
        x: hostWin.getWidgetX("network")
        y: hostWin.getWidgetY("network")
        width: 226
        height: 68
        readonly property bool isOn: hostWin.isWidgetOn("network")
        readonly property real baseScale: hostWin.getWidgetScale("network")
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
            property real dX: wNetwork.x
            property real dY: wNetwork.y
            property real dS: wNetwork.scale
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
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 34, wNetwork.x, wNetwork.y, false)
        }

        property string rxSpeed: "0 KB/s"
        property string txSpeed: "0 KB/s"
        property real lastRx: -1
        property real lastTx: -1

        Process {
            id: netProc
            running: wNetwork.visible
            command: ["sh", "-c", "awk 'NR>2 && $1!~/lo:/ {rx+=$2; tx+=$10} END {print rx, tx}' /proc/net/dev"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let parts = text.trim().split(/\s+/);
                    if (parts.length === 2) {
                        let rx = parseFloat(parts[0]) || 0, tx = parseFloat(parts[1]) || 0;
                        if (wNetwork.lastRx >= 0) {
                            let dr = Math.max(0, (rx - wNetwork.lastRx) / 2.0);
                            let dt = Math.max(0, (tx - wNetwork.lastTx) / 2.0);
                            wNetwork.rxSpeed = dr > 1048576 ? (dr / 1048576).toFixed(1) + " MB/s" : Math.round(dr / 1024) + " KB/s";
                            wNetwork.txSpeed = dt > 1048576 ? (dt / 1048576).toFixed(1) + " MB/s" : Math.round(dt / 1024) + " KB/s";
                        }
                        wNetwork.lastRx = rx; wNetwork.lastTx = tx;
                    }
                }
            }
        }
        Timer { interval: 2000; running: wNetwork.visible; repeat: true; onTriggered: netProc.running = true }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
            ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                Text { text: "↓ Download"; color: ThemeTokens.textSecondary; font.pixelSize: 9 }
                Text { text: wNetwork.rxSpeed; color: ThemeTokens.success; font.pixelSize: 12; font.bold: true }
            }
            Rectangle { width: 1; height: 28; color: ThemeTokens.dividerColor }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                Text { text: "↑ Upload"; color: ThemeTokens.textSecondary; font.pixelSize: 9 }
                Text { text: wNetwork.txSpeed; color: ThemeTokens.accent; font.pixelSize: 12; font.bold: true }
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
            onPressed: (m) => { hostWin.bringWidgetToFront("network"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wNetwork.x; oy = wNetwork.y; }
            onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("network", ox + (p.x - sx), oy + (p.y - sy)); } }
            onReleased: hostWin.saveLayout()
        }

        // Tombol Hapus (X)
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
            z: 25; width: 22; height: 22; radius: 11
            color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
            visible: hostWin.editMode
            Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("network", false) }
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
                    startScale = hostWin.getWidgetScale("network");
                }
                onPositionChanged: (m) => {
                    if (pressed) {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        let delta = (p.x - startX) / 226.0;
                        hostWin.setWidgetScale("network", startScale + delta);
                    }
                }
                onReleased: hostWin.saveLayout()
            }
        }
    }
}
