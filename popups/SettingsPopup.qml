import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../core"

Item {
    id: settingsScope
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin
    readonly property real cardOpacity: settingsCard.opacity

        // ── 4K. KAIRO SYSTEM SETTINGS (HARMONYOS LIQUID GLASS PILLS & ORBS) ──
        Process {
            id: settingsExtraProc
            Component.onCompleted: running = true
            command: ["sh", "-c", "ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}'); [ -z \"$ip_addr\" ] && ip_addr='Offline'; pprof=$(powerprofilesctl get 2>/dev/null || echo 'balanced'); printf '%s|%s\n' \"$ip_addr\" \"$pprof\""]
            stdout: StdioCollector {
                onStreamFinished: {
                    let p = text.trim().split("|");
                    if (p.length >= 2) {
                        shellRoot.localIpAddr = p[0];
                        shellRoot.powerProfile = p[1];
                    }
                }
            }
        }

        function setPowerProfile(prof) {
            shellRoot.powerProfile = prof;
            shellRoot.runCmd("powerprofilesctl set " + prof + " 2>/dev/null || true");
        }

        Rectangle {
            id: settingsCard
            z: 17
            anchors.centerIn: parent
            width: 840
            height: 628
            radius: 36
            color: "#A612141E"
            border.width: 1.2
            border.color: "#4CFFFFFF"
            clip: true
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "settings" || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }

            // Lapisan Windows 7 Aero + iOS Liquid Glass Real-Time
            Canvas {
                anchors.fill: parent
                z: 0
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
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, 36, (sw - width) * 0.5, (sh - height) * 0.5, sw, sh, false, false);
                }
            }

            // Inner Specular Rim Kaca
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 35
                color: "transparent"
                border.width: 1
                border.color: "#28FFFFFF"
            }

            property bool isOpen: shellRoot.activePopup === "settings"
            property int stage: 0

            onIsOpenChanged: {
                if (isOpen) {
                    stage = 1;
                    settingsStaggerTimer.restart();
                    settingsKeyCatcher.forceActiveFocus();
                } else {
                    settingsStaggerTimer.stop();
                    stage = 0;
                }
            }

            Timer {
                id: settingsStaggerTimer
                interval: 34
                repeat: true
                onTriggered: {
                    if (settingsCard.stage < 6) settingsCard.stage++;
                    else stop();
                }
            }

            Item {
                id: settingsKeyCatcher
                focus: settingsCard.isOpen && !setSearchInput.activeFocus && !setWifiPassField.activeFocus
                Keys.onEscapePressed: shellRoot.closePopups()
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: settingsCard.isOpen ? 0 : 16
                Behavior on y { SpringAnimation { spring: 7.5; damping: 0.72 } }
            }

            Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }
            Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16
                z: 2

                // ── SIDEBAR KIRI (KAPSUL LONJONG HARMONYOS) ───────────────
                Rectangle {
                    Layout.preferredWidth: 236
                    Layout.fillHeight: true
                    radius: 28
                    color: "#44141724"
                    border.width: 1
                    border.color: "#36FFFFFF"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // Header Traffic Light + Title
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            spacing: 8

                            Row {
                                spacing: 7
                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: closeSetM.containsMouse ? "#FF3B30" : "#FF5F56"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: "#4D0000"
                                        font.pixelSize: 10
                                        font.bold: true
                                        visible: closeSetM.containsMouse
                                    }
                                    MouseArea {
                                        id: closeSetM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.closePopups()
                                    }
                                }
                                Rectangle { width: 12; height: 12; radius: 6; color: "#FFBD2E" }
                                Rectangle { width: 12; height: 12; radius: 6; color: "#27C93F" }
                            }

                            Item { width: 4 }

                            Text {
                                text: "Settings"
                                color: "#FFFFFF"
                                font.pixelSize: 15
                                font.bold: true
                            }
                        }

                        // Kartu Profil User Pill Lonjong
                        Rectangle {
                            Layout.fillWidth: true
                            height: 54
                            radius: 27
                            border.width: 1.1
                            border.color: profilePillM.containsMouse ? "#58FFFFFF" : "#34FFFFFF"
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#32FFFFFF" }
                                GradientStop { position: 1.0; color: "#14FFFFFF" }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 12
                                spacing: 10

                                Rectangle {
                                    width: 38; height: 38; radius: 19
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#2E94FF" }
                                        GradientStop { position: 1.0; color: "#BF5AF2" }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "AR"
                                        color: "#FFFFFF"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: "Arip"
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "Kairo 26.04 • L14"
                                        color: "#C7C7CC"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Text { text: "›"; color: "#AEAEB2"; font.pixelSize: 15; font.bold: true }
                            }

                            MouseArea {
                                id: profilePillM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: shellRoot.switchPopup("about")
                            }
                        }

                        // Search Pill Lonjong
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 18
                            color: "#22FFFFFF"
                            border.width: 1
                            border.color: setSearchInput.activeFocus ? "#77A1C6FF" : "#2EFFFFFF"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 6

                                Text { text: "⌕"; color: "#AEAEB2"; font.pixelSize: 14 }

                                TextInput {
                                    id: setSearchInput
                                    Layout.fillWidth: true
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    clip: true
                                    onTextChanged: {
                                        shellRoot.settingsSearch = text;
                                        let q = text.trim().toLowerCase();
                                        if (q.includes("wifi") || q.includes("net") || q.includes("ip")) shellRoot.settingsTab = "wifi";
                                        else if (q.includes("blue") || q.includes("bt")) shellRoot.settingsTab = "bluetooth";
                                        else if (q.includes("bright") || q.includes("sound") || q.includes("vol") || q.includes("layar")) shellRoot.settingsTab = "display_sound";
                                        else if (q.includes("wall") || q.includes("dock") || q.includes("widget") || q.includes("kairo")) shellRoot.settingsTab = "appearance";
                                        else if (q.includes("bat") || q.includes("power") || q.includes("daya") || q.includes("about")) shellRoot.settingsTab = "power";
                                    }
                                    Keys.onEscapePressed: shellRoot.closePopups()

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Cari pengaturan..."
                                        color: "#8E8E93"
                                        font.pixelSize: 11
                                        visible: setSearchInput.text === ""
                                    }
                                }
                            }
                        }

                        // Daftar Kategori Kapsul Lonjong
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 7

                            Repeater {
                                model: [
                                    { id: "appearance", title: "Kairo & Wallpaper", sub: "Preview, Dock, Widget", glyph: "✦" },
                                    { id: "display_sound", title: "Display & Sound", sub: "Brightness, Volume, Focus", glyph: "☀" },
                                    { id: "wifi", title: "Wi-Fi & Network", sub: shellRoot.wifiConnected ? shellRoot.wifiName : "Terputus", glyph: "ᯤ" },
                                    { id: "bluetooth", title: "Bluetooth", sub: shellRoot.btEnabled ? "Aktif" : "Mati", glyph: "ᛒ" },
                                    { id: "power", title: "Power & System", sub: shellRoot.batteryPercent >= 0 ? ("Baterai " + shellRoot.batteryPercent + "%") : "AC Power", glyph: "⚡" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 44
                                    radius: 22
                                    property bool active: shellRoot.settingsTab === modelData.id
                                    border.width: 1.1
                                    border.color: active ? "#80FFFFFF" : (navPillM.containsMouse ? "#46FFFFFF" : "#22FFFFFF")
                                    scale: navPillM.pressed ? 0.96 : 1.0

                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: active ? "#D92B8EFF" : (navPillM.containsMouse ? "#2CFFFFFF" : "#18FFFFFF") }
                                        GradientStop { position: 1.0; color: active ? "#AD0866E6" : "#0DFFFFFF" }
                                    }

                                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        Rectangle {
                                            width: 30; height: 30; radius: 15
                                            color: active ? "#38FFFFFF" : "#24FFFFFF"
                                            border.width: 1
                                            border.color: "#36FFFFFF"
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.glyph
                                                color: "#FFFFFF"
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            Text {
                                                text: modelData.title
                                                color: "#FFFFFF"
                                                font.pixelSize: 12
                                                font.bold: active
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: modelData.sub
                                                color: active ? "#E5F2FF" : "#98989D"
                                                font.pixelSize: 9
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: navPillM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.settingsTab = modelData.id
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Tombol Pill About Kairo di Dasar Sidebar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 18
                            color: aboutShortcutM.containsMouse ? "#2EFFFFFF" : "#1CFFFFFF"
                            border.width: 1
                            border.color: "#32FFFFFF"

                            Text {
                                anchors.centerIn: parent
                                text: "About Kairo Desktop ›"
                                color: "#E5E5EA"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: aboutShortcutM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: shellRoot.switchPopup("about")
                            }
                        }
                    }
                }

                // ── PANEL KANAN (HARMONYOS GLASS PILLS, ORBS & LIVE PREVIEW) ──
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // ========================================================
                    // TAB 1: KAIRO & WALLPAPER (OPSI 3 LIVE PREVIEW + PILLS)
                    // ========================================================
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12
                        visible: shellRoot.settingsTab === "appearance"
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Kairo & Wallpaper"; color: "#FFFFFF"; font.pixelSize: 17; font.bold: true }
                            Item { Layout.fillWidth: true }

                            // Pill Next Wallpaper
                            Rectangle {
                                height: 34
                                width: nextWpPillTxt.implicitWidth + 24
                                radius: 17
                                border.width: 1.1
                                border.color: "#75FFFFFF"
                                scale: nextWpPillM.pressed ? 0.94 : 1.0
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#D92B8EFF" }
                                    GradientStop { position: 1.0; color: "#AD0866E6" }
                                }
                                Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                Text {
                                    id: nextWpPillTxt
                                    anchors.centerIn: parent
                                    text: "↻ Acak Wallpaper"
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    id: nextWpPillM
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.pickRandomWallpaper()
                                }
                            }
                        }

                        // LIVE KAIRO DESKTOP MINI-PREVIEW + KONTROL BULAT LONJONG
                        RowLayout {
                            Layout.fillWidth: true
                            height: 112
                            spacing: 12

                            // Miniatur Layar Kairo Desktop (Rounded Capsule Frame)
                            Rectangle {
                                Layout.preferredWidth: 286
                                Layout.fillHeight: true
                                radius: 26
                                color: "#1A1C28"
                                border.width: 1.2
                                border.color: "#4CFFFFFF"
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: shellRoot.currentWallpaper
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    visible: status === Image.Ready
                                }

                                // Mini Top Bar
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 14
                                    color: "#99121218"

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Rectangle { width: 5; height: 5; radius: 2.5; color: "#FFFFFF" }
                                        Rectangle { width: 18; height: 4; radius: 2; color: "#CCFFFFFF" }
                                    }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 34; height: 7; radius: 3.5
                                        color: "#44FFFFFF"
                                    }
                                }

                                // Mini Desktop Widgets
                                Row {
                                    x: 12; y: 24
                                    spacing: 6
                                    Rectangle {
                                        width: 66; height: 84; radius: 11
                                        color: "#CC18181E"; border.width: 1; border.color: "#33FFFFFF"
                                    }
                                    Column {
                                        spacing: 6
                                        Rectangle {
                                            width: 40; height: 40; radius: 20
                                            color: "#CC18181E"; border.width: 1; border.color: "#33FFFFFF"
                                        }
                                        Rectangle {
                                            width: 40; height: 38; radius: 11
                                            color: "#CC2D1F14"; border.width: 1; border.color: "#33FFFFFF"
                                        }
                                    }
                                }

                                // Mini Liquid Glass Floating Dock (Merespons Mode Auto-Hide!)
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: shellRoot.dockHideMode === "always" ? -18 : 7
                                    width: 154
                                    height: 20
                                    radius: 10
                                    color: "#AA1C1E28"
                                    border.width: 1
                                    border.color: "#55FFFFFF"
                                    Behavior on anchors.bottomMargin { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Repeater {
                                            model: ["#1D8FE1", "#5E5CE6", "#FF9500", "#30D158", "#0A84FF", "#BF5AF2"]
                                            Rectangle {
                                                width: 12; height: 12; radius: 6
                                                color: modelData
                                            }
                                        }
                                    }
                                }

                                // Badge Live Preview
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 20
                                    anchors.rightMargin: 10
                                    height: 20
                                    width: livePrevBadge.implicitWidth + 12
                                    radius: 10
                                    color: "#8812141E"
                                    border.width: 1
                                    border.color: "#44FFFFFF"
                                    Text {
                                        id: livePrevBadge
                                        anchors.centerIn: parent
                                        text: "Live Preview"
                                        color: "#FFFFFF"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }

                            // Kolom Kanan: Mode Floating Dock & Aksi Widget (Pil Bulat Lonjong)
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 8

                                Text {
                                    text: "Floating Dock Mode"
                                    color: "#D1D1D6"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                // 3 Pilihan Mode Dock berbentuk Kapsul Lonjong
                                Repeater {
                                    model: [
                                        { mode: "smart", label: "Smart Auto-Hide" },
                                        { mode: "always", label: "Selalu Sembunyi" },
                                        { mode: "never", label: "Selalu Tampil" }
                                    ]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 32
                                        radius: 16
                                        property bool isSel: shellRoot.dockHideMode === modelData.mode
                                        border.width: 1.1
                                        border.color: isSel ? "#80FFFFFF" : "#30FFFFFF"
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: isSel ? "#D92B8EFF" : "#24FFFFFF" }
                                            GradientStop { position: 1.0; color: isSel ? "#AD0866E6" : "#10FFFFFF" }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            Text {
                                                text: modelData.label
                                                color: "#FFFFFF"
                                                font.pixelSize: 11
                                                font.bold: isSel
                                            }
                                            Item { Layout.fillWidth: true }
                                            Rectangle {
                                                width: 14; height: 14; radius: 7
                                                color: isSel ? "#FFFFFF" : "transparent"
                                                border.width: 1.2
                                                border.color: "#88FFFFFF"
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: shellRoot.dockHideMode = modelData.mode
                                        }
                                    }
                                }

                                // Baris 2 Pill Aksi Widget (Atur & Reset)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        radius: 17
                                        color: editWidPillM.containsMouse ? "#34FFFFFF" : "#20FFFFFF"
                                        border.width: 1.1
                                        border.color: "#44FFFFFF"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Atur Widget"
                                            color: "#FFFFFF"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        MouseArea {
                                            id: editWidPillM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                shellRoot.closePopups();
                                                hostWin.editMode = true;
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        radius: 17
                                        color: rstWidPillM.containsMouse ? "#34FFFFFF" : "#20FFFFFF"
                                        border.width: 1.1
                                        border.color: "#44FFFFFF"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Reset Layout"
                                            color: "#E5E5EA"
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: rstWidPillM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: hostWin.resetLayout()
                                        }
                                    }
                                }
                            }
                        }

                        // ── PILIHAN 2 OPSI GLASS + SETTINGAN INDEPENDEN MASING-MASING ──
                        RowLayout {
                            Layout.fillWidth: true
                            height: 40
                            spacing: 10

                            Repeater {
                                model: [
                                    { id: "mac", title: "Opsi 1 • Clean Glass", sub: "Frost Rata Halus" },
                                    { id: "aero", title: "Opsi 2 • Aero Blin", sub: "Pantulan Diagonal" },
                                    { id: "liquid", title: "Opsi 3 • Liquid Glass", sub: "Refraksi Niri-Glass" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 40
                                    radius: 20
                                    property bool active: shellRoot.glassStyle === modelData.id
                                    border.width: 1.15
                                    border.color: active ? "#85FFFFFF" : "#3CFFFFFF"
                                    scale: optPillM.pressed ? 0.96 : 1.0
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: active ? "#D92B8EFF" : "#26FFFFFF" }
                                        GradientStop { position: 1.0; color: active ? "#AD0866E6" : "#12FFFFFF" }
                                    }
                                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 12
                                        spacing: 8

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            Text {
                                                text: modelData.title
                                                color: "#FFFFFF"
                                                font.pixelSize: 11
                                                font.bold: active
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: modelData.sub
                                                color: active ? "#E5F2FF" : "#AEAEB2"
                                                font.pixelSize: 9
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        Rectangle {
                                            width: 14; height: 14; radius: 7
                                            color: active ? "#FFFFFF" : "transparent"
                                            border.width: 1.2
                                            border.color: "#88FFFFFF"
                                        }
                                    }

                                    MouseArea {
                                        id: optPillM
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.glassStyle = modelData.id;
                                            hostWin.saveLayout();
                                        }
                                    }
                                }
                            }
                        }

                        // SLIDER INDEPENDEN OPSI 1 (CLEAN GLASS: TRANSPARANSI & BLIN RATA)
                        RowLayout {
                            Layout.fillWidth: true
                            height: 40
                            spacing: 10
                            visible: shellRoot.glassStyle === "mac"

                            // Slider 1A: Transparansi Opsi 1
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 20
                                color: "#22FFFFFF"
                                border.width: 1.1
                                border.color: "#48FFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(40, parent.width * Math.max(0.12, Math.min(0.90, 1.0 - shellRoot.macOpacity)))
                                    height: 40
                                    radius: 20
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#72FFFFFF" }
                                        GradientStop { position: 1.0; color: "#44FFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#60FFFFFF"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    Text { text: "◌"; color: "#FFFFFF"; font.pixelSize: 14; font.bold: true }
                                    Text { text: "Transparansi"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Math.round((1.0 - shellRoot.macOpacity) * 100) + "%"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => {
                                        let t = Math.max(0.15, Math.min(0.90, m.x / width));
                                        shellRoot.macOpacity = Number((1.0 - t).toFixed(2));
                                    }
                                    onPositionChanged: (m) => {
                                        if (pressed) {
                                            let t = Math.max(0.15, Math.min(0.90, m.x / width));
                                            shellRoot.macOpacity = Number((1.0 - t).toFixed(2));
                                        }
                                    }
                                    onReleased: hostWin.saveLayout()
                                }
                            }

                            // Slider 1B: Blin Rata Opsi 1
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 20
                                color: "#22FFFFFF"
                                border.width: 1.1
                                border.color: "#48FFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(40, parent.width * shellRoot.macFrost)
                                    height: 40
                                    radius: 20
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#72FFFFFF" }
                                        GradientStop { position: 1.0; color: "#44FFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#60FFFFFF"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    Text { text: "✦"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                                    Text { text: "Blin Rata"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Math.round(shellRoot.macFrost * 100) + "%"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => shellRoot.macFrost = Number(Math.max(0.0, Math.min(1.0, m.x / width)).toFixed(2))
                                    onPositionChanged: (m) => { if (pressed) shellRoot.macFrost = Number(Math.max(0.0, Math.min(1.0, m.x / width)).toFixed(2)); }
                                    onReleased: hostWin.saveLayout()
                                }
                            }
                        }

                        // SLIDER INDEPENDEN OPSI 2 (AERO BLIN: TRANSPARANSI, KECERAHAN BLIN & KETEBALAN BLIN)
                        RowLayout {
                            Layout.fillWidth: true
                            height: 40
                            spacing: 8
                            visible: shellRoot.glassStyle === "aero"

                            // Slider 2A: Transparansi Opsi 2
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 20
                                color: "#22FFFFFF"
                                border.width: 1.1
                                border.color: "#48FFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(36, parent.width * Math.max(0.12, Math.min(0.90, 1.0 - shellRoot.aeroBaseOpacity)))
                                    height: 40
                                    radius: 20
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#72FFFFFF" }
                                        GradientStop { position: 1.0; color: "#44FFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#60FFFFFF"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    Text { text: "Transparansi"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Math.round((1.0 - shellRoot.aeroBaseOpacity) * 100) + "%"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => {
                                        let t = Math.max(0.15, Math.min(0.90, m.x / width));
                                        shellRoot.aeroBaseOpacity = Number((1.0 - t).toFixed(2));
                                    }
                                    onPositionChanged: (m) => {
                                        if (pressed) {
                                            let t = Math.max(0.15, Math.min(0.90, m.x / width));
                                            shellRoot.aeroBaseOpacity = Number((1.0 - t).toFixed(2));
                                        }
                                    }
                                    onReleased: hostWin.saveLayout()
                                }
                            }

                            // Slider 2B: Kecerahan Blin Opsi 2
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 20
                                color: "#22FFFFFF"
                                border.width: 1.1
                                border.color: "#48FFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(36, parent.width * shellRoot.aeroSheenBright)
                                    height: 40
                                    radius: 20
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#72FFFFFF" }
                                        GradientStop { position: 1.0; color: "#44FFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#60FFFFFF"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    Text { text: "Cerah Blin"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Math.round(shellRoot.aeroSheenBright * 100) + "%"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => shellRoot.aeroSheenBright = Number(Math.max(0.0, Math.min(1.0, m.x / width)).toFixed(2))
                                    onPositionChanged: (m) => { if (pressed) shellRoot.aeroSheenBright = Number(Math.max(0.0, Math.min(1.0, m.x / width)).toFixed(2)); }
                                    onReleased: hostWin.saveLayout()
                                }
                            }

                            // Slider 2C: Ketebalan Blin Opsi 2
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 20
                                color: "#22FFFFFF"
                                border.width: 1.1
                                border.color: "#48FFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(36, parent.width * shellRoot.aeroSheenWidth)
                                    height: 40
                                    radius: 20
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#72FFFFFF" }
                                        GradientStop { position: 1.0; color: "#44FFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#60FFFFFF"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    Text { text: "Tebal Blin"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Math.round(shellRoot.aeroSheenWidth * 100) + "%"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => shellRoot.aeroSheenWidth = Number(Math.max(0.08, Math.min(1.0, m.x / width)).toFixed(2))
                                    onPositionChanged: (m) => { if (pressed) shellRoot.aeroSheenWidth = Number(Math.max(0.08, Math.min(1.0, m.x / width)).toFixed(2)); }
                                    onReleased: hostWin.saveLayout()
                                }
                            }
                        }

                        // SLIDER INDEPENDEN OPSI 3 (LIQUID GLASS: TRANSPARANSI, REFRAKSI & PRISMA RGB)
                        RowLayout {
                            Layout.fillWidth: true
                            height: 40
                            spacing: 8
                            visible: shellRoot.glassStyle === "liquid"

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 20
                                color: "#22FFFFFF"
                                border.width: 1.1
                                border.color: "#48FFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(36, parent.width * Math.max(0.12, Math.min(0.90, 1.0 - shellRoot.liquidOpacity)))
                                    height: 40
                                    radius: 20
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#72FFFFFF" }
                                        GradientStop { position: 1.0; color: "#44FFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#60FFFFFF"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    Text { text: "Transparansi"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Math.round((1.0 - shellRoot.liquidOpacity) * 100) + "%"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => {
                                        let t = Math.max(0.15, Math.min(0.90, m.x / width));
                                        shellRoot.liquidOpacity = Number((1.0 - t).toFixed(2));
                                    }
                                    onPositionChanged: (m) => {
                                        if (pressed) {
                                            let t = Math.max(0.15, Math.min(0.90, m.x / width));
                                            shellRoot.liquidOpacity = Number((1.0 - t).toFixed(2));
                                        }
                                    }
                                    onReleased: hostWin.saveLayout()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 20
                                color: "#22FFFFFF"
                                border.width: 1.1
                                border.color: "#48FFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(36, parent.width * shellRoot.liquidRefraction)
                                    height: 40
                                    radius: 20
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#72FFFFFF" }
                                        GradientStop { position: 1.0; color: "#44FFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#60FFFFFF"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    Text { text: "Refraksi"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Math.round(shellRoot.liquidRefraction * 100) + "%"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => shellRoot.liquidRefraction = Number(Math.max(0.0, Math.min(1.0, m.x / width)).toFixed(2))
                                    onPositionChanged: (m) => { if (pressed) shellRoot.liquidRefraction = Number(Math.max(0.0, Math.min(1.0, m.x / width)).toFixed(2)); }
                                    onReleased: hostWin.saveLayout()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 20
                                color: "#22FFFFFF"
                                border.width: 1.1
                                border.color: "#48FFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(36, parent.width * shellRoot.liquidFringing)
                                    height: 40
                                    radius: 20
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#72FFFFFF" }
                                        GradientStop { position: 1.0; color: "#44FFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#60FFFFFF"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    Text { text: "Prisma RGB"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Math.round(shellRoot.liquidFringing * 100) + "%"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => shellRoot.liquidFringing = Number(Math.max(0.0, Math.min(1.0, m.x / width)).toFixed(2))
                                    onPositionChanged: (m) => { if (pressed) shellRoot.liquidFringing = Number(Math.max(0.0, Math.min(1.0, m.x / width)).toFixed(2)); }
                                    onReleased: hostWin.saveLayout()
                                }
                            }
                        }

                        // Galeri Pilihan Wallpaper (Pill Rounded Thumbnails)
                        // ── WIDGET GALLERY (PILIH WIDGET 1-1 & KUNCI POSISI) ──
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Widget Desktop (Klik untuk Tampilkan / Sembunyikan)"
                                color: "#D1D1D6"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                height: 24; width: setLockTxt.implicitWidth + 16; radius: 12
                                color: hostWin.widgetsLocked ? "#44FFD60A" : "#22FFFFFF"
                                border.width: 1; border.color: hostWin.widgetsLocked ? "#88FFD60A" : "#3CFFFFFF"
                                Text {
                                    id: setLockTxt
                                    anchors.centerIn: parent
                                    text: hostWin.widgetsLocked ? "🔒 Posisi Terkunci" : "🔓 Posisi Bebas"
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
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 7

                            Repeater {
                                model: [
                                    { key: "media", label: "♫ Media Player" },
                                    { key: "clock", label: "🕒 Analog Clock" },
                                    { key: "weather", label: "☀ Weather" },
                                    { key: "battery", label: "🔋 Batteries Ring" },
                                    { key: "sysmon", label: "⚡ CPU & RAM" },
                                    { key: "notes", label: "📝 Calendar & Notes" }
                                ]

                                Rectangle {
                                    height: 30
                                    width: wChipTxt.implicitWidth + 24
                                    radius: 15
                                    property bool active: hostWin.isWidgetOn(modelData.key)
                                    border.width: 1.1
                                    border.color: active ? "#85FFFFFF" : "#38FFFFFF"
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: active ? "#D92B8EFF" : "#24FFFFFF" }
                                        GradientStop { position: 1.0; color: active ? "#AD0866E6" : "#12FFFFFF" }
                                    }

                                    Text {
                                        id: wChipTxt
                                        anchors.centerIn: parent
                                        text: (active ? "✓ " : "+ ") + modelData.label
                                        color: "#FFFFFF"
                                        font.pixelSize: 10
                                        font.bold: active
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: hostWin.setWidgetEnabled(modelData.key, !active)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Koleksi Wallpaper (" + shellRoot.wallpaperList.length + " tersedia)"
                            color: "#D1D1D6"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        GridView {
                            id: wallGrid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            cellWidth: Math.floor(width / 3)
                            cellHeight: 74
                            model: shellRoot.wallpaperList

                            delegate: Item {
                                width: wallGrid.cellWidth
                                height: wallGrid.cellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    radius: 22
                                    color: "#222534"
                                    border.width: shellRoot.currentWallpaper === modelData ? 2 : 1.1
                                    border.color: shellRoot.currentWallpaper === modelData ? "#64D2FF" : "#3CFFFFFF"
                                    clip: true
                                    scale: wpThumbM.pressed ? 0.94 : (wpThumbM.containsMouse ? 1.03 : 1.0)
                                    Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                    Image {
                                        anchors.fill: parent
                                        source: modelData
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize: Qt.size(260, 160)
                                        asynchronous: true
                                        smooth: true
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 7
                                        width: 22; height: 22; radius: 11
                                        color: "#0A84FF"
                                        border.width: 1
                                        border.color: "#FFFFFF"
                                        visible: shellRoot.currentWallpaper === modelData
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            color: "#FFFFFF"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        id: wpThumbM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.currentWallpaper = modelData
                                    }
                                }
                            }
                        }
                    }

                    // ========================================================
                    // TAB 2: DISPLAY & SOUND (HARMONYOS GLASS PILLS & ORBS)
                    // ========================================================
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 14
                        visible: shellRoot.settingsTab === "display_sound"
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                        Text { text: "Display & Sound"; color: "#FFFFFF"; font.pixelSize: 17; font.bold: true }

                        // BARIS 1: 2 KAPSUL LONJONG BESAR ALA HARMONYOS (DND PILL + BRIGHTNESS PILL SLIDER)
                        RowLayout {
                            Layout.fillWidth: true
                            height: 58
                            spacing: 12

                            // Kapsul Lonjong Focus / Do Not Disturb (Persis kiri atas gambar referensi)
                            Rectangle {
                                Layout.fillWidth: true
                                height: 58
                                radius: 29
                                border.width: 1.2
                                border.color: shellRoot.dndEnabled ? "#85FFFFFF" : "#48FFFFFF"
                                scale: setDndPillM.pressed ? 0.96 : 1.0
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: shellRoot.dndEnabled ? "#D92B8EFF" : "#2EFFFFFF" }
                                    GradientStop { position: 1.0; color: shellRoot.dndEnabled ? "#AD0866E6" : "#14FFFFFF" }
                                }
                                Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 18
                                    spacing: 12

                                    Text { text: "☾"; color: "#FFFFFF"; font.pixelSize: 20; font.bold: true }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: "Do Not Disturb"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                                        Text { text: shellRoot.dndEnabled ? "Aktif • Notifikasi Hening" : "Nonaktif"; color: "#E5E5EA"; font.pixelSize: 10 }
                                    }
                                }

                                MouseArea {
                                    id: setDndPillM
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.toggleDnd()
                                }
                            }

                            // Slider Pil Kaca Brightness (Persis kanan atas gambar referensi)
                            Rectangle {
                                Layout.fillWidth: true
                                height: 58
                                radius: 29
                                color: "#22FFFFFF"
                                border.width: 1.2
                                border.color: "#4CFFFFFF"
                                clip: true

                                Rectangle {
                                    width: Math.max(58, parent.width * (shellRoot.brightnessLevel / 100))
                                    height: 58
                                    radius: 29
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#78FFFFFF" }
                                        GradientStop { position: 1.0; color: "#4CFFFFFF" }
                                    }
                                    border.width: 1
                                    border.color: "#66FFFFFF"
                                    Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.InOutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 18
                                    anchors.rightMargin: 18
                                    Text { text: "☀"; color: "#FFFFFF"; font.pixelSize: 19; font.bold: true }
                                    Text { text: "Brightness"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: shellRoot.brightnessLevel + "%"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (m) => shellRoot.setBrightnessPct((m.x / width) * 100)
                                    onPositionChanged: (m) => { if (pressed) shellRoot.setBrightnessPct((m.x / width) * 100); }
                                }
                            }
                        }

                        // BARIS 2: SLIDER PIL KACA SOUND VOLUME
                        Rectangle {
                            Layout.fillWidth: true
                            height: 58
                            radius: 29
                            color: "#22FFFFFF"
                            border.width: 1.2
                            border.color: "#4CFFFFFF"
                            clip: true

                            Rectangle {
                                width: shellRoot.volumeMuted ? 58 : Math.max(58, parent.width * (shellRoot.volumeLevel / 100))
                                height: 58
                                radius: 29
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: shellRoot.volumeMuted ? "#44FF453A" : "#78FFFFFF" }
                                    GradientStop { position: 1.0; color: shellRoot.volumeMuted ? "#28FF453A" : "#4CFFFFFF" }
                                }
                                border.width: 1
                                border.color: "#66FFFFFF"
                                Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.InOutCubic } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                Text { text: shellRoot.volumeMuted ? "🔇" : "🔊"; font.pixelSize: 17 }
                                Text { text: "Master Volume"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: shellRoot.volumeMuted ? "Muted" : (shellRoot.volumeLevel + "%")
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (m) => shellRoot.setVolumePct((m.x / width) * 100)
                                onPositionChanged: (m) => { if (pressed) shellRoot.setVolumePct((m.x / width) * 100); }
                            }
                        }

                        // BARIS 3: 4 TOMBOL BULAT KACA (CIRCULAR GLASS ORBS ALA HARMONYOS)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Repeater {
                                model: [
                                    { label: "Keep Awake", glyph: "⏱", active: shellRoot.keepAwake, act: "awake" },
                                    { label: "Mute Audio", glyph: "🔇", active: shellRoot.volumeMuted, act: "mute" },
                                    { label: "Screenshot", glyph: "📷", active: false, act: "ss" },
                                    { label: "Overview", glyph: "⊞", active: false, act: "ov" }
                                ]

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: 62
                                        height: 62
                                        radius: 31
                                        border.width: 1.2
                                        border.color: modelData.active ? "#88FFFFFF" : "#4CFFFFFF"
                                        scale: orbM1.pressed ? 0.92 : (orbM1.containsMouse ? 1.05 : 1.0)
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: modelData.active ? "#E02E94FF" : "#30FFFFFF" }
                                            GradientStop { position: 1.0; color: modelData.active ? "#AD0866E6" : "#14FFFFFF" }
                                        }
                                        Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.glyph
                                            color: "#FFFFFF"
                                            font.pixelSize: 21
                                        }

                                        MouseArea {
                                            id: orbM1
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.act === "awake") shellRoot.toggleKeepAwake();
                                                else if (modelData.act === "mute") shellRoot.toggleMute();
                                                else if (modelData.act === "ss") { shellRoot.closePopups(); screenshotDelayTimer.restart(); }
                                                else if (modelData.act === "ov") { shellRoot.closePopups(); shellRoot.runCmd("niri msg action toggle-overview"); }
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.label
                                        color: "#E5E5EA"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }

                        // BARIS 4: INFO OUTPUT LAYAR (KAPSUL LONJONG)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 26
                            color: "#22FFFFFF"
                            border.width: 1.1
                            border.color: "#38FFFFFF"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                Text { text: "Layar Utama • " + shellRoot.sysSpecs.displayInfo; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                                Item { Layout.fillWidth: true }
                                Text { text: shellRoot.sysSpecs.gpuModel; color: "#C7C7CC"; font.pixelSize: 11; elide: Text.ElideRight; Layout.maximumWidth: 250 }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ========================================================
                    // TAB 3: WI-FI & NETWORK (KAPSUL LONJONG + ORB SCAN)
                    // ========================================================
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12
                        visible: shellRoot.settingsTab === "wifi"
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Kapsul Toggle Wi-Fi
                            Rectangle {
                                Layout.fillWidth: true
                                height: 54
                                radius: 27
                                border.width: 1.2
                                border.color: shellRoot.wifiEnabled ? "#85FFFFFF" : "#48FFFFFF"
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: shellRoot.wifiEnabled ? "#D92B8EFF" : "#2EFFFFFF" }
                                    GradientStop { position: 1.0; color: shellRoot.wifiEnabled ? "#AD0866E6" : "#14FFFFFF" }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 18
                                    spacing: 12

                                    Text { text: "ᯤ"; color: "#FFFFFF"; font.pixelSize: 18; font.bold: true }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: "Wi-Fi"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                                        Text { text: shellRoot.wifiName + " • IP " + shellRoot.localIpAddr; color: "#E5F2FF"; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }
                                    Text { text: shellRoot.wifiEnabled ? "ON" : "OFF"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.toggleWifi()
                                }
                            }

                            // Tombol Bulat Kaca Rescan Wi-Fi
                            Rectangle {
                                width: 54; height: 54; radius: 27
                                border.width: 1.2
                                border.color: "#4CFFFFFF"
                                visible: shellRoot.wifiEnabled
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#30FFFFFF" }
                                    GradientStop { position: 1.0; color: "#14FFFFFF" }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: shellRoot.wifiScanning ? "…" : "↻"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.scanWifiNetworks()
                                }
                            }
                        }

                        // Kapsul Input Sandi Wi-Fi
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 24
                            color: "#2EFFFFFF"
                            border.width: 1.2
                            border.color: "#66A1C6FF"
                            visible: shellRoot.wifiPasswordTarget !== ""

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 8
                                spacing: 8

                                TextInput {
                                    id: setWifiPassField
                                    Layout.fillWidth: true
                                    echoMode: TextInput.Password
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    onAccepted: shellRoot.connectWifi(shellRoot.wifiPasswordTarget, text)
                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Sandi untuk " + shellRoot.wifiPasswordTarget + "..."
                                        color: "#C7C7CC"
                                        font.pixelSize: 11
                                        visible: setWifiPassField.text === ""
                                    }
                                }

                                Rectangle {
                                    height: 34
                                    width: 96
                                    radius: 17
                                    color: "#0A84FF"
                                    Text { anchors.centerIn: parent; text: "Hubungkan"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.connectWifi(shellRoot.wifiPasswordTarget, setWifiPassField.text)
                                    }
                                }
                            }
                        }

                        // Daftar Jaringan Wi-Fi (Kapsul Lonjong)
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            visible: shellRoot.wifiEnabled
                            model: shellRoot.wifiNetworks

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 46
                                radius: 23
                                border.width: 1.1
                                border.color: modelData.connected ? "#80FFFFFF" : "#30FFFFFF"
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: modelData.connected ? "#CC2B8EFF" : (wPillM.containsMouse ? "#2CFFFFFF" : "#1CFFFFFF") }
                                    GradientStop { position: 1.0; color: modelData.connected ? "#990866E6" : "#0EFFFFFF" }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 16
                                    spacing: 10

                                    Rectangle {
                                        width: 26; height: 26; radius: 13
                                        color: "#33FFFFFF"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.connected ? "✓" : "ᯤ"
                                            color: "#FFFFFF"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.ssid
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        font.bold: modelData.connected
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: (modelData.secured ? "🔒 " : "") + modelData.signal + "%"
                                        color: "#E5E5EA"
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: wPillM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) return;
                                        if (modelData.secured) {
                                            shellRoot.wifiPasswordTarget = modelData.ssid;
                                            setWifiPassField.text = "";
                                            setWifiPassField.forceActiveFocus();
                                        }
                                        shellRoot.connectWifi(modelData.ssid, "");
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true; visible: !shellRoot.wifiEnabled }
                    }

                    // ========================================================
                    // TAB 4: BLUETOOTH (KAPSUL LONJONG + ORB SCAN)
                    // ========================================================
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12
                        visible: shellRoot.settingsTab === "bluetooth"
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                height: 54
                                radius: 27
                                border.width: 1.2
                                border.color: shellRoot.btEnabled ? "#85FFFFFF" : "#48FFFFFF"
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: shellRoot.btEnabled ? "#D92B8EFF" : "#2EFFFFFF" }
                                    GradientStop { position: 1.0; color: shellRoot.btEnabled ? "#AD0866E6" : "#14FFFFFF" }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 18
                                    spacing: 12

                                    Text { text: "ᛒ"; color: "#FFFFFF"; font.pixelSize: 18; font.bold: true }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: "Bluetooth"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                                        Text { text: shellRoot.btEnabled ? (shellRoot.btDeviceName !== "" ? "Terhubung: " + shellRoot.btDeviceName : "Siap dipasangkan") : "Bluetooth Nonaktif"; color: "#E5F2FF"; font.pixelSize: 10 }
                                    }
                                    Text { text: shellRoot.btEnabled ? "ON" : "OFF"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.toggleBluetooth()
                                }
                            }

                            Rectangle {
                                width: 54; height: 54; radius: 27
                                border.width: 1.2
                                border.color: "#4CFFFFFF"
                                visible: shellRoot.btEnabled
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#30FFFFFF" }
                                    GradientStop { position: 1.0; color: "#14FFFFFF" }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: shellRoot.btScanning ? "…" : "↻"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.scanBtDevices()
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            visible: shellRoot.btEnabled
                            model: shellRoot.btDevices

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 48
                                radius: 24
                                border.width: 1.1
                                border.color: modelData.connected ? "#80FFFFFF" : "#30FFFFFF"
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: modelData.connected ? "#CC2B8EFF" : (btPillM.containsMouse ? "#2CFFFFFF" : "#1CFFFFFF") }
                                    GradientStop { position: 1.0; color: modelData.connected ? "#990866E6" : "#0EFFFFFF" }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 16
                                    spacing: 10

                                    Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: "#33FFFFFF"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.connected ? "✓" : "ᛒ"
                                            color: "#FFFFFF"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        font.bold: modelData.connected
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: shellRoot.btBusyMac === modelData.mac ? "Proses..." : (modelData.connected ? "Terhubung" : "Hubungkan")
                                        color: modelData.connected ? "#32D74B" : "#E5E5EA"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: btPillM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.toggleBtDevice(modelData.mac, modelData.connected)
                                }
                            }
                        }

                        Item { Layout.fillHeight: true; visible: !shellRoot.btEnabled }
                    }

                    // ========================================================
                    // TAB 5: POWER & SYSTEM (PILL PROFILES + POWER ORBS)
                    // ========================================================
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 14
                        visible: shellRoot.settingsTab === "power"
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }

                        Text { text: "Power & System"; color: "#FFFFFF"; font.pixelSize: 17; font.bold: true }

                        // Kapsul Status Baterai
                        Rectangle {
                            Layout.fillWidth: true
                            height: 58
                            radius: 29
                            color: "#22FFFFFF"
                            border.width: 1.2
                            border.color: "#4CFFFFFF"
                            clip: true

                            Rectangle {
                                width: shellRoot.batteryPercent >= 0 ? Math.max(58, parent.width * (shellRoot.batteryPercent / 100)) : parent.width
                                height: 58
                                radius: 29
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: shellRoot.batteryStatus === "Charging" ? "#5532D74B" : "#552E94FF" }
                                    GradientStop { position: 1.0; color: "#22FFFFFF" }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                Text { text: shellRoot.batteryStatus === "Charging" ? "⚡" : "🔋"; font.pixelSize: 18 }
                                Text {
                                    text: shellRoot.batteryPercent >= 0 ? ("Baterai " + shellRoot.batteryPercent + "% (" + shellRoot.batteryStatus + ")") : "Daya Listrik Langsung (AC)"
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                                Item { Layout.fillWidth: true }
                                Text { text: "Up " + shellRoot.sysSpecs.uptimeStr; color: "#E5E5EA"; font.pixelSize: 11 }
                            }
                        }

                        // 3 Pil Mode Performa CPU
                        Text { text: "Mode Performa Daya"; color: "#D1D1D6"; font.pixelSize: 11; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: [
                                    { id: "power-saver", label: "Hemat Daya" },
                                    { id: "balanced", label: "Seimbang" },
                                    { id: "performance", label: "Performa" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 44
                                    radius: 22
                                    property bool active: shellRoot.powerProfile === modelData.id
                                    border.width: 1.2
                                    border.color: active ? "#85FFFFFF" : "#38FFFFFF"
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: active ? "#D92B8EFF" : "#26FFFFFF" }
                                        GradientStop { position: 1.0; color: active ? "#AD0866E6" : "#12FFFFFF" }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        font.bold: active
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.setPowerProfile(modelData.id)
                                    }
                                }
                            }
                        }

                        // 4 Tombol Bulat Kaca Daya (Lock, Sleep, Restart, Shutdown)
                        Text { text: "Kontrol Sesi & Daya"; color: "#D1D1D6"; font.pixelSize: 11; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Repeater {
                                model: [
                                    { label: "Lock Screen", glyph: "🔒", cmd: "swaylock -f -c 000000 || loginctl lock-session" },
                                    { label: "Sleep", glyph: "☾", cmd: "systemctl suspend" },
                                    { label: "Restart", glyph: "↻", cmd: "systemctl reboot" },
                                    { label: "Shut Down", glyph: "⏻", cmd: "systemctl poweroff" }
                                ]

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: 62
                                        height: 62
                                        radius: 31
                                        border.width: 1.2
                                        border.color: pwrOrbM.containsMouse ? "#80FFFFFF" : "#48FFFFFF"
                                        scale: pwrOrbM.pressed ? 0.92 : (pwrOrbM.containsMouse ? 1.05 : 1.0)
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: pwrOrbM.containsMouse ? "#45FFFFFF" : "#2CFFFFFF" }
                                            GradientStop { position: 1.0; color: "#14FFFFFF" }
                                        }
                                        Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.glyph
                                            color: "#FFFFFF"
                                            font.pixelSize: 20
                                        }

                                        MouseArea {
                                            id: pwrOrbM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                shellRoot.closePopups();
                                                shellRoot.runCmd(modelData.cmd);
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.label
                                        color: "#E5E5EA"
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

}
