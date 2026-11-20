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
            id: wMedia
            x: win.getWidgetX("media")
            y: win.getWidgetY("media")
            width: 226
            height: 296
            scale: win.widgetScale
            transformOrigin: Item.TopLeft
            visible: win.isWidgetOn("media")
            opacity: root.bootStage >= 2 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

            Canvas {
                anchors.fill: parent
                property real dX: wMedia.x
                property real dY: wMedia.y
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
                onPaint: win.drawWidgetGlass(getContext("2d"), width, height, 24, wMedia.x, wMedia.y, false)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 64; height: 64; radius: 14
                        color: "#28FFFFFF"
                        border.width: 1
                        border.color: "#44FFFFFF"
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: root.mediaArtUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: root.mediaArtUrl !== "" && status === Image.Ready
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            visible: !root.mediaArtUrl || root.mediaArtUrl === ""
                            Repeater {
                                model: [14, 24, 18]
                                Rectangle { width: 4; height: modelData; radius: 2; color: "#A1C6FF"; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text {
                            text: root.mediaTitle
                            color: "#FFFFFF"
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.mediaArtist
                            color: "#B4B4BC"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        Layout.fillWidth: true
                        height: 4; radius: 2; color: "#2CFFFFFF"
                        Rectangle {
                            width: root.mediaLength > 0 ? parent.width * Math.min(1, root.mediaPosition / root.mediaLength) : 0
                            height: 4; radius: 2; color: "#A1C6FF"
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.formatTime(root.mediaPosition); color: "#8E8E93"; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: root.formatTime(root.mediaLength); color: "#8E8E93"; font.pixelSize: 10 }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 22

                    Text {
                        text: "⏮"
                        color: "#FFFFFF"
                        font.pixelSize: 18
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("playerctl previous") }
                    }

                    Rectangle {
                        width: 44; height: 44; radius: 22
                        color: "#A1C6FF"
                        Text {
                            anchors.centerIn: parent
                            text: root.mediaPlaying ? "⏸" : "▶"
                            color: "#0C101A"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("playerctl play-pause") }
                    }

                    Text {
                        text: "⏭"
                        color: "#FFFFFF"
                        font.pixelSize: 18
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.runCmd("playerctl next") }
                    }
                }
            }

            // Drag Handle Saat Edit Mode (Tidak Aktif Jika Locked)
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
                onPressed: (m) => { let p = mapToItem(win.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wMedia.x; oy = wMedia.y; }
                onPositionChanged: (m) => { if (pressed) { let p = mapToItem(win.contentItem, m.x, m.y); win.setWidgetPos("media", ox + (p.x - sx), oy + (p.y - sy)); } }
                onReleased: win.saveLayout()
            }

            // Tombol Sembunyikan Widget Saat Edit Mode
            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
                z: 25; width: 22; height: 22; radius: 11
                color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
                visible: win.editMode
                Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.setWidgetEnabled("media", false) }
            }
        }
}
