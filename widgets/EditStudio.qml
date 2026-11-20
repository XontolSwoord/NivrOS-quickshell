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
            id: widgetCtxMenu
            z: 60
            x: hostWin.ctxMenuX
            y: hostWin.ctxMenuY
            width: 156
            height: 112
            visible: hostWin.ctxMenuVisible || opacity > 0.01
            opacity: hostWin.ctxMenuVisible ? 1.0 : 0.0
            scale: hostWin.ctxMenuVisible ? 1.0 : 0.90
            transformOrigin: Item.TopLeft

            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 165; easing.type: Easing.InOutCubic } }

            Canvas {
                anchors.fill: parent
                property real dX: widgetCtxMenu.x
                property real dY: widgetCtxMenu.y
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
                onDXChanged: requestPaint()
                onDYChanged: requestPaint()
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 18, widgetCtxMenu.x, widgetCtxMenu.y, false)
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
                        Text { text: hostWin.editMode ? "✓" : "✥"; color: "#A1C6FF"; font.pixelSize: 12; font.bold: true }
                        Text {
                            text: hostWin.editMode ? "Selesai Atur" : "Atur Widget"
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
                            hostWin.ctxMenuVisible = false;
                            if (hostWin.editMode) {
                                hostWin.editMode = false;
                                hostWin.saveLayout();
                            } else {
                                hostWin.editMode = true;
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
                        Text { text: hostWin.widgetsLocked ? "🔓" : "🔒"; font.pixelSize: 11 }
                        Text {
                            text: hostWin.widgetsLocked ? "Buka Kunci" : "Lock Posisi"
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
                            hostWin.ctxMenuVisible = false;
                            hostWin.toggleLock();
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
                            hostWin.ctxMenuVisible = false;
                            shellRoot.settingsTab = "appearance";
                            shellRoot.switchPopup("settings");
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
            visible: hostWin.editMode

            RowLayout {
                id: editToolbarRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: hostWin.widgetsLocked ? "🔒 Terkunci" : "✥ Geser Tiap Widget"
                    color: hostWin.widgetsLocked ? "#FFD60A" : "#E5E5EA"
                    font.pixelSize: 11
                    font.bold: true
                }

                // Tombol Lock / Unlock Posisi
                Rectangle {
                    height: 24; width: lockBtnTxt.implicitWidth + 16; radius: 12
                    color: hostWin.widgetsLocked ? "#44FFD60A" : "#24FFFFFF"
                    border.width: 1; border.color: hostWin.widgetsLocked ? "#88FFD60A" : "#3CFFFFFF"
                    Text {
                        id: lockBtnTxt
                        anchors.centerIn: parent
                        text: hostWin.widgetsLocked ? "Buka Kunci" : "Lock"
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hostWin.toggleLock()
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
                            hostWin.editMode = false;
                            hostWin.saveLayout();
                            shellRoot.settingsTab = "appearance";
                            shellRoot.switchPopup("settings");
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
                        onClicked: hostWin.resetLayout()
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
                            hostWin.editMode = false;
                            hostWin.saveLayout();
                        }
                    }
                }
            }
        }
}
