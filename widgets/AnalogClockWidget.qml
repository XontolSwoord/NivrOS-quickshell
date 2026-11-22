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
        id: wAnalog
        x: hostWin.getWidgetX("analog")
        y: hostWin.getWidgetY("analog")
        width: 168
        height: 168
        readonly property bool isOn: hostWin.isWidgetOn("analog")
        readonly property real baseScale: hostWin.getWidgetScale("analog")
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
            property real dX: wAnalog.x
            property real dY: wAnalog.y
            property real dS: wAnalog.scale
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
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 84, wAnalog.x, wAnalog.y, true)
        }

        Canvas {
            id: analogFace
            anchors.fill: parent
            anchors.margins: 10
            property date now: new Date()
            Timer { interval: 1000; running: wAnalog.visible; repeat: true; onTriggered: { analogFace.now = new Date(); analogFace.requestPaint(); } }
            onPaint: {
                let ctx = getContext("2d"); ctx.reset();
                let cx = width / 2, cy = height / 2, r = Math.min(cx, cy) - 4;
                ctx.strokeStyle = ThemeTokens.isDark ? "rgba(255,255,255,0.45)" : "rgba(0,0,0,0.45)";
                for (let i = 0; i < 12; i++) {
                    let a = (i * 30 - 90) * Math.PI / 180;
                    ctx.lineWidth = (i % 3 === 0) ? 2.2 : 1.1;
                    ctx.beginPath();
                    ctx.moveTo(cx + Math.cos(a) * (r - 8), cy + Math.sin(a) * (r - 8));
                    ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r);
                    ctx.stroke();
                }
                let hr = now.getHours() % 12, mn = now.getMinutes(), sc = now.getSeconds();
                let ha = ((hr + mn / 60.0) * 30 - 90) * Math.PI / 180;
                let ma = ((mn + sc / 60.0) * 6 - 90) * Math.PI / 180;
                let sa = (sc * 6 - 90) * Math.PI / 180;

                ctx.strokeStyle = ThemeTokens.textPrimary; ctx.lineCap = "round";
                ctx.lineWidth = 3.2; ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(ha) * (r * 0.52), cy + Math.sin(ha) * (r * 0.52)); ctx.stroke();
                ctx.lineWidth = 2.1; ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(ma) * (r * 0.74), cy + Math.sin(ma) * (r * 0.74)); ctx.stroke();
                ctx.strokeStyle = ThemeTokens.accent; ctx.lineWidth = 1.3;
                ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(sa) * (r * 0.82), cy + Math.sin(sa) * (r * 0.82)); ctx.stroke();
                ctx.fillStyle = ThemeTokens.accent; ctx.beginPath(); ctx.arc(cx, cy, 3.2, 0, Math.PI * 2); ctx.fill();
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
            onPressed: (m) => { hostWin.bringWidgetToFront("analog"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wAnalog.x; oy = wAnalog.y; }
            onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("analog", ox + (p.x - sx), oy + (p.y - sy)); } }
            onReleased: hostWin.saveLayout()
        }

        // Tombol Hapus (X)
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
            z: 25; width: 22; height: 22; radius: 11
            color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
            visible: hostWin.editMode
            Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("analog", false) }
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
                    startScale = hostWin.getWidgetScale("analog");
                }
                onPositionChanged: (m) => {
                    if (pressed) {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        let delta = (p.x - startX) / 168.0;
                        hostWin.setWidgetScale("analog", startScale + delta);
                    }
                }
                onReleased: hostWin.saveLayout()
            }
        }
    }
}
