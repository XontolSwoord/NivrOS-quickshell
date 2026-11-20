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
    id: modRoot
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin
    readonly property bool anyVisible: (wifiCard.opacity > 0.01 || btCard.opacity > 0.01)

        Rectangle {
            id: wifiCard
            z: 10
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 4
            anchors.rightMargin: 10
            width: 318
            height: wifiPopupCol.implicitHeight + 24
            radius: 22
            color: "transparent"
            Canvas {
                anchors.fill: parent
                z: -1
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDFChanged: requestPaint()
                onDWChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: {
                    let sw = Screen.width || 1366;
                    let sh = Screen.height || 768;
                    let pos = parent.mapToItem(null, 0, 0);
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, parent.radius, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: "#38FFFFFF"
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "wifi" || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "wifi")
            property int stage: 0
            onIsOpenChanged: {
                if (isOpen) {
                    stage = 1;
                    wifiStaggerTimer.restart();
                } else {
                    wifiStaggerTimer.stop();
                    stage = 0;
                }
            }

            Timer {
                id: wifiStaggerTimer
                interval: 34
                repeat: true
                onTriggered: {
                    if (wifiCard.stage < 12) wifiCard.stage++;
                    else stop();
                }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: wifiCard.isOpen ? 0 : -12
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopRight

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

            Column {
                id: wifiPopupCol
                x: 14
                y: 12
                z: 2
                width: 290
                spacing: 10

                RowLayout {
                    width: 290
                    opacity: wifiCard.stage >= 1 ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: backWifiM.containsMouse ? "#2EFFFFFF" : "#1AFFFFFF"
                        Text { anchors.centerIn: parent; text: "‹"; color: "#F5F5F7"; font.pixelSize: 15; font.bold: true }
                        MouseArea {
                            id: backWifiM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onPressed: shellRoot.switchPopup("cc")
                        }
                    }

                    Text { text: "Wi-Fi Sekitar"; color: "#F5F5F7"; font.pixelSize: 13; font.bold: true }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: scanWifiM.containsMouse ? "#2EFFFFFF" : "#1AFFFFFF"
                        visible: shellRoot.wifiEnabled
                        Text { anchors.centerIn: parent; text: shellRoot.wifiScanning ? "…" : "↻"; color: "#A1C6FF"; font.pixelSize: 12; font.bold: true }
                        MouseArea {
                            id: scanWifiM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.scanWifiNetworks()
                        }
                    }

                    Rectangle {
                        width: 42; height: 24; radius: 12
                        color: shellRoot.wifiEnabled ? "#0A84FF" : "#3A3A40"
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            x: shellRoot.wifiEnabled ? 20 : 2
                            y: 2
                            width: 20; height: 20; radius: 10
                            color: "#FFFFFF"
                            Behavior on x { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.toggleWifi()
                        }
                    }
                }

                Rectangle {
                    width: 290
                    height: 68
                    radius: 14
                    color: "#26FFFFFF"
                    border.width: 1
                    border.color: "#44A1C6FF"
                    visible: shellRoot.wifiPasswordTarget !== ""

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        Text {
                            text: "Sandi untuk " + shellRoot.wifiPasswordTarget
                            color: "#F5F5F7"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Row {
                            width: parent.width
                            spacing: 6

                            TextField {
                                id: wifiPassField
                                width: 196
                                height: 28
                                echoMode: TextInput.Password
                                placeholderText: "Masukkan sandi Wi-Fi..."
                                color: "#FFFFFF"
                                font.pixelSize: 11
                                background: Rectangle {
                                    radius: 8
                                    color: "#44000000"
                                    border.width: 1
                                    border.color: "#33FFFFFF"
                                }
                                onAccepted: shellRoot.connectWifi(shellRoot.wifiPasswordTarget, text)
                            }

                            Rectangle {
                                width: 72
                                height: 28
                                radius: 8
                                color: "#0A84FF"
                                Text { anchors.centerIn: parent; text: "Hubungkan"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    z: 5
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.connectWifi(shellRoot.wifiPasswordTarget, wifiPassField.text)
                                }
                            }
                        }
                    }
                }

                Text { width: 290; text: shellRoot.wifiStatusMsg; color: "#A1C6FF"; font.pixelSize: 11; visible: shellRoot.wifiStatusMsg !== "" }

                Column {
                    width: 290
                    spacing: 5
                    visible: shellRoot.wifiEnabled

                    Text {
                        width: 290
                        horizontalAlignment: Text.AlignHCenter
                        text: shellRoot.wifiScanning ? "Memindai jaringan Wi-Fi..." : "Tidak ada jaringan ditemukan"
                        color: "#8E8E93"
                        font.pixelSize: 11
                        visible: shellRoot.wifiNetworks.length === 0
                    }

                    Repeater {
                        model: shellRoot.wifiNetworks

                        Rectangle {
                            width: 290
                            height: 36
                            radius: 11
                            color: netRowM.containsMouse ? "#2AFFFFFF" : (modelData.connected ? "#220A84FF" : "#18FFFFFF")
                            border.width: modelData.connected ? 1 : 0
                            border.color: "#550A84FF"

                            opacity: wifiCard.stage >= (index + 2) ? 1.0 : 0.0
                            transform: Translate {
                                y: wifiCard.stage >= (index + 2) ? 0 : 8
                                Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                            }
                            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 22; height: 22; radius: 11
                                    color: modelData.connected ? "#0A84FF" : "#3A3A40"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "✓" : "ᯤ"
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 175
                                    text: modelData.ssid
                                    color: "#F5F5F7"
                                    font.pixelSize: 12
                                    font.weight: modelData.connected ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (modelData.secured ? "🔒 " : "") + modelData.signal + "%"
                                    color: "#AEAEB2"
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: netRowM
                                anchors.fill: parent
                                z: 5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) return;
                                    if (modelData.secured) {
                                        shellRoot.wifiPasswordTarget = modelData.ssid;
                                        wifiPassField.text = "";
                                        wifiPassField.forceActiveFocus();
                                    }
                                    shellRoot.connectWifi(modelData.ssid, "");
                                }
                            }
                        }
                    }
                }

                Text {
                    width: 290
                    horizontalAlignment: Text.AlignHCenter
                    text: "Wi-Fi dimatikan. Aktifkan sakelar di atas untuk memindai."
                    color: "#8E8E93"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    visible: !shellRoot.wifiEnabled
                }
            }
        }
        Rectangle {
            id: btCard
            z: 10
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 4
            anchors.rightMargin: 10
            width: 318
            height: btPopupCol.implicitHeight + 24
            radius: 22
            color: "transparent"
            Canvas {
                anchors.fill: parent
                z: -1
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: shellRoot.glassStyle
                property real dTh: shellRoot.activeGlassDetail
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDFChanged: requestPaint()
                onDWChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: {
                    let sw = Screen.width || 1366;
                    let sh = Screen.height || 768;
                    let pos = parent.mapToItem(null, 0, 0);
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, parent.radius, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: "#38FFFFFF"
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "bt" || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "bt")
            property int stage: 0
            onIsOpenChanged: {
                if (isOpen) {
                    stage = 1;
                    btStaggerTimer.restart();
                } else {
                    btStaggerTimer.stop();
                    stage = 0;
                }
            }

            Timer {
                id: btStaggerTimer
                interval: 34
                repeat: true
                onTriggered: {
                    if (btCard.stage < 12) btCard.stage++;
                    else stop();
                }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: btCard.isOpen ? 0 : -12
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }
            transformOrigin: Item.TopRight

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

            Column {
                id: btPopupCol
                x: 14
                y: 12
                z: 2
                width: 290
                spacing: 10

                RowLayout {
                    width: 290
                    opacity: btCard.stage >= 1 ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: backBtM.containsMouse ? "#2EFFFFFF" : "#1AFFFFFF"
                        Text { anchors.centerIn: parent; text: "‹"; color: "#F5F5F7"; font.pixelSize: 15; font.bold: true }
                        MouseArea {
                            id: backBtM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onPressed: shellRoot.switchPopup("cc")
                        }
                    }

                    Text { text: "Bluetooth Tersedia"; color: "#F5F5F7"; font.pixelSize: 13; font.bold: true }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: scanBtM.containsMouse ? "#2EFFFFFF" : "#1AFFFFFF"
                        visible: shellRoot.btEnabled
                        Text { anchors.centerIn: parent; text: shellRoot.btScanning ? "…" : "↻"; color: "#A1C6FF"; font.pixelSize: 12; font.bold: true }
                        MouseArea {
                            id: scanBtM; anchors.fill: parent; z: 5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.scanBtDevices()
                        }
                    }

                    Rectangle {
                        width: 42; height: 24; radius: 12
                        color: shellRoot.btEnabled ? "#0A84FF" : "#3A3A40"
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            x: shellRoot.btEnabled ? 20 : 2
                            y: 2
                            width: 20; height: 20; radius: 10
                            color: "#FFFFFF"
                            Behavior on x { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.toggleBluetooth()
                        }
                    }
                }

                Column {
                    width: 290
                    spacing: 5
                    visible: shellRoot.btEnabled

                    Text {
                        width: 290
                        horizontalAlignment: Text.AlignHCenter
                        text: shellRoot.btScanning ? "Memindai perangkat Bluetooth..." : "Tidak ada perangkat ditemukan"
                        color: "#8E8E93"
                        font.pixelSize: 11
                        visible: shellRoot.btDevices.length === 0
                    }

                    Repeater {
                        model: shellRoot.btDevices

                        Rectangle {
                            width: 290
                            height: 38
                            radius: 11
                            color: btDevM.containsMouse ? "#2AFFFFFF" : (modelData.connected ? "#220A84FF" : "#18FFFFFF")
                            border.width: modelData.connected ? 1 : 0
                            border.color: "#550A84FF"

                            opacity: btCard.stage >= (index + 2) ? 1.0 : 0.0
                            transform: Translate {
                                y: btCard.stage >= (index + 2) ? 0 : 8
                                Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                            }
                            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24; height: 24; radius: 12
                                    color: modelData.connected ? "#0A84FF" : "#3A3A40"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "✓" : "ᛒ"
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 162
                                    text: modelData.name
                                    color: "#F5F5F7"
                                    font.pixelSize: 12
                                    font.weight: modelData.connected ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: shellRoot.btBusyMac === modelData.mac ? "Proses..."
                                          : (modelData.connected ? "Terhubung" : (modelData.paired ? "Tersimpan" : "Pasangkan"))
                                    color: modelData.connected ? "#32D74B" : "#AEAEB2"
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: btDevM
                                anchors.fill: parent
                                z: 5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shellRoot.toggleBtDevice(modelData.mac, modelData.connected)
                            }
                        }
                    }
                }

                Text {
                    width: 290
                    horizontalAlignment: Text.AlignHCenter
                    text: "Bluetooth dimatikan. Aktifkan sakelar di atas untuk memindai perangkat."
                    color: "#8E8E93"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    visible: !shellRoot.btEnabled
                }
            }
        }
}
