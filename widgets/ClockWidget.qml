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
            id: wClock
            x: hostWin.getWidgetX("clock")
            y: hostWin.getWidgetY("clock")
            width: 148
            height: 148
            scale: hostWin.getWidgetScale("clock")
            transformOrigin: Item.TopLeft
        Behavior on x { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: !resizeArea.pressed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            visible: hostWin.isWidgetOn("clock")
            opacity: shellRoot.bootStage >= 3 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

            Canvas {
                anchors.fill: parent
                property real dX: wClock.x
                property real dY: wClock.y
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
                property bool dDark: ThemeTokens.isDark
                onDDarkChanged: requestPaint()
                property real dTh: shellRoot.activeGlassDetail
                onDXChanged: requestPaint()
                onDYChanged: requestPaint()
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 74, wClock.x, wClock.y, true)
            }

            Canvas {
                id: analogClockFace
                anchors.fill: parent
                property date now: new Date()
                Timer {
                    interval: 1000
                    running: wClock.visible
                    repeat: true
                    onTriggered: { analogClockFace.now = new Date(); analogClockFace.requestPaint(); }
                }
                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();
                    let cx = width / 2, cy = height / 2, r = width / 2 - 8;
                    for (let i = 0; i < 60; i++) {
                        let ang = (i * 6 - 90) * Math.PI / 180;
                        let isMajor = i % 5 === 0;
                        let r1 = isMajor ? r - 9 : r - 4;
                        ctx.strokeStyle = isMajor ? (ThemeTokens.isDark ? "rgba(255,255,255," : "rgba(24,24,28,") + "0.88)" : (ThemeTokens.isDark ? "rgba(255,255,255," : "rgba(24,24,28,") + "0.34)";
                        ctx.lineWidth = isMajor ? 1.8 : 1.0;
                        ctx.beginPath();
                        ctx.moveTo(cx + Math.cos(ang) * r1, cy + Math.sin(ang) * r1);
                        ctx.lineTo(cx + Math.cos(ang) * r, cy + Math.sin(ang) * r);
                        ctx.stroke();
                    }
                    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                    ctx.fillStyle = "rgba(235,235,245,0.78)";
                    ctx.font = "600 10px sans-serif";
                    ctx.textAlign = "center";
                    ctx.fillText(days[now.getDay()] + " " + now.getDate(), cx, cy + 22);

                    let sec = now.getSeconds();
                    let min = now.getMinutes() + sec / 60;
                    let hr = (now.getHours() % 12) + min / 60;

                    let hAng = (hr * 30 - 90) * Math.PI / 180;
                    ctx.strokeStyle = "#FFFFFF";
                    ctx.lineWidth = 3.2;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.lineTo(cx + Math.cos(hAng) * (r * 0.52), cy + Math.sin(hAng) * (r * 0.52));
                    ctx.stroke();

                    let mAng = (min * 6 - 90) * Math.PI / 180;
                    ctx.lineWidth = 2.2;
                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.lineTo(cx + Math.cos(mAng) * (r * 0.74), cy + Math.sin(mAng) * (r * 0.74));
                    ctx.stroke();

                    let sAng = (sec * 6 - 90) * Math.PI / 180;
                    ctx.strokeStyle = "#FF9F0A";
                    ctx.lineWidth = 1.4;
                    ctx.beginPath();
                    ctx.moveTo(cx - Math.cos(sAng) * 10, cy - Math.sin(sAng) * 10);
                    ctx.lineTo(cx + Math.cos(sAng) * (r * 0.80), cy + Math.sin(sAng) * (r * 0.80));
                    ctx.stroke();

                    ctx.fillStyle = "#FF9F0A";
                    ctx.beginPath();
                    ctx.arc(cx, cy, 3.2, 0, Math.PI * 2);
                    ctx.fill();
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
                onPressed: (m) => { hostWin.bringWidgetToFront("clock"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wClock.x; oy = wClock.y; }
                onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("clock", ox + (p.x - sx), oy + (p.y - sy)); } }
                onReleased: hostWin.saveLayout()
            }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -4
                z: 25; width: 22; height: 22; radius: 11
                color: "#FF453A"; border.width: 1; border.color: ThemeTokens.textPrimary
                visible: hostWin.editMode
                Text { anchors.centerIn: parent; text: "×"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("clock", false) }
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
                        startScale = hostWin.getWidgetScale("clock");
                    }
                    onPositionChanged: (m) => {
                        if (pressed) {
                            let p = mapToItem(hostWin.contentItem, m.x, m.y);
                            let delta = (p.x - startX) / 226.0;
                            hostWin.setWidgetScale("clock", startScale + delta);
                        }
                    }
                    onReleased: hostWin.saveLayout()
                }
            }
        }
}
