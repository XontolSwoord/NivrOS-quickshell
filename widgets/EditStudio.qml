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
            id: widgetCtxMenu
            z: 60
            x: win.ctxMenuX
            y: win.ctxMenuY
            width: 156
            height: 112
            visible: win.ctxMenuVisible || opacity > 0.01
            opacity: win.ctxMenuVisible ? 1.0 : 0.0
            scale: win.ctxMenuVisible ? 1.0 : 0.90
            transformOrigin: Item.TopLeft

            Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }
            Behavior on scale { NumberAnimation { duration: 165; easing.type: Easing.InOutCubic } }

            Canvas {
                anchors.fill: parent
                property real dX: widgetCtxMenu.x
                property real dY: widgetCtxMenu.y
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
                onPaint: win.drawWidgetGlass(getContext("2d"), width, height, 18, widgetCtxMenu.x, widgetCtxMenu.y, false)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 7
                spacing: 4

                // Opsi 1: Masuk / Keluar Mode Atur Widget
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 13
                    color: ctxOpt1M.containsMouse ? "#34FFFFFF" : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        Text { text: win.editMode ? "✓" : "✥"; color: "#A1C6FF"; font.pixelSize: 12; font.bold: true }
                        Text {
                            text: win.editMode ? "Selesai Atur" : "Atur Widget"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: ctxOpt1M
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.ctxMenuVisible = false;
                            if (win.editMode) {
                                win.editMode = false;
                                win.saveLayout();
                            } else {
                                win.editMode = true;
                            }
                        }
                    }
                }

                // Opsi 2: Kunci / Buka Kunci Posisi Widget
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 13
                    color: ctxOpt2M.containsMouse ? "#34FFFFFF" : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        Text { text: win.widgetsLocked ? "🔓" : "🔒"; font.pixelSize: 11 }
                        Text {
                            text: win.widgetsLocked ? "Buka Kunci" : "Lock Posisi"
                            color: "#F5F5F7"
                            font.pixelSize: 11
                        }
                        Item { Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: ctxOpt2M
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.ctxMenuVisible = false;
                            win.toggleLock();
                        }
                    }
                }

                // Opsi 3: Tambah / Pilih Widget di Gallery
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 13
                    color: ctxOpt3M.containsMouse ? "#34FFFFFF" : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        Text { text: "+"; color: "#32D74B"; font.pixelSize: 14; font.bold: true }
                        Text {
                            text: "Pilih Widget"
                            color: "#F5F5F7"
                            font.pixelSize: 11
                        }
                        Item { Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: ctxOpt3M
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.ctxMenuVisible = false;
                            root.settingsTab = "appearance";
                            root.switchPopup("settings");
                        }
                    }
                }
            }
        }
        Rectangle {
            id: editToolbar
            z: 50
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 12
            height: 38
            width: editToolbarRow.implicitWidth + 24
            radius: 19
            color: "#D9181A24"
            border.width: 1.1
            border.color: "#55FFFFFF"
            visible: win.editMode

            RowLayout {
                id: editToolbarRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: win.widgetsLocked ? "🔒 Terkunci" : "✥ Geser Tiap Widget"
                    color: win.widgetsLocked ? "#FFD60A" : "#E5E5EA"
                    font.pixelSize: 11
                    font.bold: true
                }

                // Tombol Lock / Unlock Posisi
                Rectangle {
                    height: 24; width: lockBtnTxt.implicitWidth + 16; radius: 12
                    color: win.widgetsLocked ? "#44FFD60A" : "#24FFFFFF"
                    border.width: 1; border.color: win.widgetsLocked ? "#88FFD60A" : "#3CFFFFFF"
                    Text {
                        id: lockBtnTxt
                        anchors.centerIn: parent
                        text: win.widgetsLocked ? "Buka Kunci" : "Lock"
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.toggleLock()
                    }
                }

                // Tombol + Tambah / Pilih Widget (Buka Gallery di Settings)
                Rectangle {
                    height: 24; width: addWidTxt.implicitWidth + 16; radius: 12
                    color: "#28FFFFFF"
                    border.width: 1; border.color: "#44FFFFFF"
                    Text {
                        id: addWidTxt
                        anchors.centerIn: parent
                        text: "+ Widget"
                        color: "#A1C6FF"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.editMode = false;
                            win.saveLayout();
                            root.settingsTab = "appearance";
                            root.switchPopup("settings");
                        }
                    }
                }

                // Tombol Reset Posisi
                Rectangle {
                    height: 24; width: 48; radius: 12
                    color: "#24FFFFFF"
                    Text { anchors.centerIn: parent; text: "Reset"; color: "#FFFFFF"; font.pixelSize: 10 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.resetLayout()
                    }
                }

                // Tombol Selesai
                Rectangle {
                    height: 24; width: 56; radius: 12
                    color: "#0A84FF"
                    Text { anchors.centerIn: parent; text: "Selesai"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.editMode = false;
                            win.saveLayout();
                        }
                    }
                }
            }
        }
}
