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
        id: wPomodoro
        x: hostWin.getWidgetX("pomodoro")
        y: hostWin.getWidgetY("pomodoro")
        width: 176
        height: 176
        readonly property bool isOn: hostWin.isWidgetOn("pomodoro")
        readonly property real baseScale: hostWin.getWidgetScale("pomodoro")
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
            property real dX: wPomodoro.x
            property real dY: wPomodoro.y
            property real dS: wPomodoro.scale
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
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 88, wPomodoro.x, wPomodoro.y, true)
        }

        property int totalSec: 1500
        property int remSec: 1500
        property bool activeRun: false

        Timer {
            interval: 1000; running: wPomodoro.activeRun; repeat: true
            onTriggered: {
                if (wPomodoro.remSec > 0) { wPomodoro.remSec -= 1; pomoRing.requestPaint(); }
                else { wPomodoro.activeRun = false; }
            }
        }

        Canvas {
            id: pomoRing
            anchors.fill: parent; anchors.margins: 10
            onPaint: {
                let ctx = getContext("2d"); ctx.reset();
                let cx = width / 2, cy = height / 2, r = Math.min(cx, cy) - 6;
                ctx.lineWidth = 5;
                ctx.strokeStyle = ThemeTokens.inputBg;
                ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke();
                let prog = wPomodoro.remSec / Math.max(1, wPomodoro.totalSec);
                ctx.strokeStyle = ThemeTokens.accent; ctx.lineCap = "round";
                ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * prog); ctx.stroke();
            }
        }

        Column {
            anchors.centerIn: parent; spacing: 4; z: 19
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "FOCUS"
                color: ThemeTokens.textSecondary; font.pixelSize: 9; font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String(Math.floor(wPomodoro.remSec / 60)).padStart(2, "0") + ":" + String(wPomodoro.remSec % 60).padStart(2, "0")
                color: ThemeTokens.textPrimary; font.pixelSize: 22; font.bold: true
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                Rectangle {
                    height: 20; width: 44; radius: 10; color: ThemeTokens.accent
                    Text { anchors.centerIn: parent; text: wPomodoro.activeRun ? "Pause" : "Start"; color: "#FFFFFF"; font.pixelSize: 9; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wPomodoro.activeRun = !wPomodoro.activeRun }
                }
                Rectangle {
                    height: 20; width: 38; radius: 10; color: ThemeTokens.inputBg
                    Text { anchors.centerIn: parent; text: "Reset"; color: ThemeTokens.textPrimary; font.pixelSize: 9 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { wPomodoro.activeRun = false; wPomodoro.remSec = wPomodoro.totalSec; pomoRing.requestPaint(); } }
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

        // Drag Posisi
        MouseArea {
            anchors.fill: parent
            z: 20
            visible: hostWin.editMode && !hostWin.widgetsLocked
            id: dragArea
            cursorShape: Qt.SizeAllCursor
            property real sx: 0; property real sy: 0; property real ox: 0; property real oy: 0
            onPressed: (m) => { hostWin.bringWidgetToFront("pomodoro"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wPomodoro.x; oy = wPomodoro.y; }
            onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("pomodoro", ox + (p.x - sx), oy + (p.y - sy)); } }
            onReleased: hostWin.saveLayout()
        }

        // Tombol Hapus (X)
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
            z: 25; width: 22; height: 22; radius: 11
            color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
            visible: hostWin.editMode
            Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("pomodoro", false) }
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
                    startScale = hostWin.getWidgetScale("pomodoro");
                }
                onPositionChanged: (m) => {
                    if (pressed) {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        let delta = (p.x - startX) / 176.0;
                        hostWin.setWidgetScale("pomodoro", startScale + delta);
                    }
                }
                onReleased: hostWin.saveLayout()
            }
        }
    }
}
