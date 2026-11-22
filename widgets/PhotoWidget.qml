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
        id: wPhoto
        x: hostWin.getWidgetX("photo")
        y: hostWin.getWidgetY("photo")
        width: 186
        height: 186
        readonly property bool isOn: hostWin.isWidgetOn("photo")
        readonly property real baseScale: hostWin.getWidgetScale("photo")
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
            property real dX: wPhoto.x
            property real dY: wPhoto.y
            property real dS: wPhoto.scale
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
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 26, wPhoto.x, wPhoto.y, false)
        }

        property int photoIdx: 0
        readonly property string activePhoto: {
            let list = shellRoot.wallpaperList || [];
            if (list.length === 0) return shellRoot.currentWallpaper || "";
            let item = String(list[photoIdx % list.length] || "");
            return item.startsWith("file://") ? item : ("file://" + item);
        }

        Rectangle {
            anchors.fill: parent; anchors.margins: 6; radius: 20; clip: true; color: ThemeTokens.inputBg
            Image {
                anchors.fill: parent
                source: wPhoto.activePhoto
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Rectangle {
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 28
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#99000000" }
                }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                    text: "Memories"
                    color: "#FFFFFF"; font.pixelSize: 10; font.bold: true
                }
            }
            MouseArea {
                anchors.fill: parent; z: 19; cursorShape: Qt.PointingHandCursor
                onClicked: wPhoto.photoIdx += 1
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
            onPressed: (m) => { hostWin.bringWidgetToFront("photo"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wPhoto.x; oy = wPhoto.y; }
            onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("photo", ox + (p.x - sx), oy + (p.y - sy)); } }
            onReleased: hostWin.saveLayout()
        }

        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
            z: 25; width: 22; height: 22; radius: 11
            color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
            visible: hostWin.editMode
            Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("photo", false) }
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
                    startScale = hostWin.getWidgetScale("photo");
                }
                onPositionChanged: (m) => {
                    if (pressed) {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        let delta = (p.x - startX) / 186.0;
                        hostWin.setWidgetScale("photo", startScale + delta);
                    }
                }
                onReleased: hostWin.saveLayout()
            }
        }
    }
}
