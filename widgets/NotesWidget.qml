import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../core"

Item {
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin
    readonly property bool noteFocused: noteInputArea.activeFocus

        Item {
            id: wNotes
            x: hostWin.getWidgetX("notes")
            y: hostWin.getWidgetY("notes")
            width: 226
            height: 206
            scale: hostWin.widgetScale
            transformOrigin: Item.TopLeft
            visible: hostWin.isWidgetOn("notes")

            SystemClock {
                id: notesClock
                precision: SystemClock.Minutes
            }

            Canvas {
                anchors.fill: parent
                property real dX: wNotes.x
                property real dY: wNotes.y
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
                property real dSc: hostWin.widgetScale
                onDXChanged: requestPaint()
                onDYChanged: requestPaint()
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onDScChanged: requestPaint()
                onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 24, wNotes.x, wNotes.y, false)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header Kalender Hari Ini ala macOS
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 10
                        color: "#22FFFFFF"
                        border.width: 1; border.color: "#38FFFFFF"
                        Column {
                            anchors.centerIn: parent
                            spacing: -1
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: notesClock.date.toLocaleString(Qt.locale("id_ID"), "ddd").toUpperCase()
                                color: "#FF453A"
                                font.pixelSize: 8
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDate(notesClock.date, "d")
                                color: "#FFFFFF"
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: notesClock.date.toLocaleString(Qt.locale("id_ID"), "MMMM yyyy")
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Text {
                            text: hostWin.editMode ? "Mode Atur Widget" : "Quick Notes • Klik untuk mengetik"
                            color: "#AEAEB2"
                            font.pixelSize: 9
                        }
                    }
                }

                // Area Tulis Catatan Interaktif (Auto-Save & Auto-Scroll)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: noteInputArea.activeFocus ? "#24FFFFFF" : "#14FFFFFF"
                    border.width: 1
                    border.color: noteInputArea.activeFocus ? "#66A1C6FF" : "#28FFFFFF"

                    Timer {
                        id: noteSaveDebounce
                        interval: 600
                        onTriggered: hostWin.saveLayout()
                    }

                    Flickable {
                        id: noteFlick
                        anchors.fill: parent
                        anchors.margins: 8
                        contentWidth: width
                        contentHeight: Math.max(noteInputArea.paintedHeight, height)
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "Tulis catatan di sini..."
                            color: "#66FFFFFF"
                            font.pixelSize: 11
                            visible: noteInputArea.text.length === 0 && !noteInputArea.activeFocus && !hostWin.editMode
                        }

                        TextEdit {
                            id: noteInputArea
                            width: noteFlick.width
                            height: Math.max(paintedHeight, noteFlick.height)
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            color: "#F5F5F7"
                            selectionColor: "#550A84FF"
                            font.pixelSize: 11
                            text: hostWin.quickNoteText
                            enabled: !hostWin.editMode
                            onCursorRectangleChanged: {
                                let r = cursorRectangle;
                                if (r.y < noteFlick.contentY) {
                                    noteFlick.contentY = r.y;
                                } else if (r.y + r.height > noteFlick.contentY + noteFlick.height) {
                                    noteFlick.contentY = r.y + r.height - noteFlick.height;
                                }
                            }
                            onActiveFocusChanged: {
                                if (!activeFocus && noteSaveDebounce.running) {
                                    noteSaveDebounce.stop();
                                    hostWin.saveLayout();
                                }
                            }
                            Component.onDestruction: {
                                if (noteSaveDebounce.running) {
                                    noteSaveDebounce.stop();
                                    hostWin.saveLayout();
                                }
                            }
                            onTextChanged: {
                                if (hostWin.quickNoteText !== text) {
                                    hostWin.quickNoteText = text;
                                    shellRoot.widgetCfg.noteText = text;
                                    noteSaveDebounce.restart();
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 18
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
                cursorShape: Qt.SizeAllCursor
                property real sx: 0; property real sy: 0; property real ox: 0; property real oy: 0
                onPressed: (m) => { let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wNotes.x; oy = wNotes.y; }
                onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("notes", ox + (p.x - sx), oy + (p.y - sy)); } }
                onReleased: hostWin.saveLayout()
            }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
                z: 25; width: 22; height: 22; radius: 11
                color: "#FF453A"; border.width: 1; border.color: "#FFFFFF"
                visible: hostWin.editMode
                Text { anchors.centerIn: parent; text: "×"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("notes", false) }
            }
        }
}
