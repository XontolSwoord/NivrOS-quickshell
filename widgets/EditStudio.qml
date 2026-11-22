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
    id: editStudioRoot
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin

    property bool galleryOpen: false
    property string activeSection: "widget" // "wallpaper" | "widget"
    property int selectedWpIndex: 0
    property int selectedWidgetIndex: 0
    property real targetWpX: 0
    property real targetWidgetX: 0

    function imgUri(raw) {
        let s = String(raw || "").trim();
        if (s === "") return "";
        return (s.startsWith("file://") || s.startsWith("image://")) ? s : ("file://" + s);
    }

    function animateWpTo(rawX) {
        if (wpStrip.width <= 0) return;
        let maxX = Math.max(0, wpStrip.contentWidth - wpStrip.width);
        targetWpX = Math.max(0, Math.min(maxX, rawX));
        wpScrollAnim.stop();
        wpScrollAnim.to = targetWpX;
        wpScrollAnim.start();
    }

    function animateWidgetTo(rawX) {
        if (widgetCarousel.width <= 0) return;
        let maxX = Math.max(0, widgetCarousel.contentWidth - widgetCarousel.width);
        targetWidgetX = Math.max(0, Math.min(maxX, rawX));
        widgetScrollAnim.stop();
        widgetScrollAnim.to = targetWidgetX;
        widgetScrollAnim.start();
    }

    function scrollToWallpaper(idx) {
        let count = shellRoot.wallpaperList ? shellRoot.wallpaperList.length : 0;
        if (count <= 0 || wpStrip.width <= 0) return;
        let clamped = Math.max(0, Math.min(count - 1, idx));
        let itemStep = 79; // width 72 + spacing 7
        animateWpTo(clamped * itemStep - (wpStrip.width - 72) / 2);
    }

    function scrollToWidget(idx) {
        let count = widgetCatalog.length;
        if (count <= 0 || widgetCarousel.width <= 0) return;
        let clamped = Math.max(0, Math.min(count - 1, idx));
        let itemStep = 182; // width 172 + spacing 10
        animateWidgetTo(clamped * itemStep - (widgetCarousel.width - 172) / 2);
    }

    onGalleryOpenChanged: {
        hostWin.widgetGalleryOpen = galleryOpen;
        if (galleryOpen) {
            activeSection = "widget";
            let list = shellRoot.wallpaperList || [];
            let curUri = imgUri(shellRoot.currentWallpaper);
            let foundWp = 0;
            for (let i = 0; i < list.length; i++) {
                if (imgUri(list[i]) === curUri) { foundWp = i; break; }
            }
            selectedWpIndex = foundWp;
            focusGrabTimer.restart();
        }
    }

    Timer {
        id: focusGrabTimer
        interval: 30
        repeat: false
        onTriggered: {
            homeWidgetDrawer.forceActiveFocus();
            editStudioRoot.scrollToWallpaper(editStudioRoot.selectedWpIndex);
            editStudioRoot.scrollToWidget(editStudioRoot.selectedWidgetIndex);
        }
    }

    readonly property var widgetCatalog: [
        { key: "calendar",   title: "Kalender",         sub: "Grid tanggal macOS" },
        { key: "worldclock", title: "World Clock",      sub: "Jakarta • Tokyo • London" },
        { key: "reminders",  title: "Reminders",        sub: "Checklist tugas interaktif" },
        { key: "photo",      title: "Photo Frame",      sub: "Bingkai kenangan kaca" },
        { key: "shortcuts",  title: "Quick Shortcuts",  sub: "Grid 2x2 aksi cepat" },
        { key: "analog",     title: "Jam Analog",       sub: "Dial bundar jarum detik" },
        { key: "pomodoro",   title: "Focus Timer",      sub: "Ring fokus 25 menit" },
        { key: "weather",    title: "Cuaca",            sub: "Suhu & kondisi lokal" },
        { key: "storage",    title: "Storage Disk",     sub: "Kapasitas partisi utama" },
        { key: "network",    title: "Network Speed",    sub: "Download & Upload live" },
        { key: "quote",      title: "Daily Insight",    sub: "Banner kutipan harian" },
        { key: "notes",      title: "Catatan",          sub: "Memo cepat di desktop" },
        { key: "battery",    title: "Baterai",          sub: "Ring daya perangkat" },
        { key: "clock",      title: "Jam Digital",      sub: "Waktu & hari saat ini" },
        { key: "media",      title: "Music Player",     sub: "Kontrol lagu & MPRIS" },
        { key: "sysmon",     title: "Aktivitas Sistem", sub: "CPU, suhu & memori" }
    ]

    Connections {
        target: hostWin
        function onEditModeChanged() {
            if (!hostWin.editMode) editStudioRoot.galleryOpen = false;
        }
    }

    // ── Menu Konteks Klik Kanan Widget ──────────────────────────────────────
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

        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Canvas {
            anchors.fill: parent
            property real dX: widgetCtxMenu.x
            property real dY: widgetCtxMenu.y
            property real dO: shellRoot.aeroOpacity
            property real dR: shellRoot.aeroReflection
            property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
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

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 13
                color: ctxOpt1M.containsMouse ? "#34FFFFFF" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Text { text: hostWin.editMode ? "✓" : "✥"; color: "#A1C6FF"; font.pixelSize: 12; font.bold: true }
                    Text { text: hostWin.editMode ? "Selesai Atur" : "Atur Widget"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.bold: true }
                    Item { Layout.fillWidth: true }
                }
                MouseArea {
                    id: ctxOpt1M; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        hostWin.ctxMenuVisible = false;
                        if (hostWin.editMode) { hostWin.editMode = false; hostWin.saveLayout(); }
                        else { hostWin.editMode = true; }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 13
                color: ctxOpt2M.containsMouse ? "#34FFFFFF" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Text { text: hostWin.widgetsLocked ? "🔓" : "🔒"; font.pixelSize: 11 }
                    Text { text: hostWin.widgetsLocked ? "Buka Kunci" : "Lock Posisi"; color: ThemeTokens.textPrimary; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                }
                MouseArea {
                    id: ctxOpt2M; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { hostWin.ctxMenuVisible = false; hostWin.toggleLock(); }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 13
                color: ctxOpt3M.containsMouse ? "#34FFFFFF" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Text { text: "+"; color: "#32D74B"; font.pixelSize: 14; font.bold: true }
                    Text { text: "Pilih Widget"; color: ThemeTokens.textPrimary; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                }
                MouseArea {
                    id: ctxOpt3M; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { hostWin.ctxMenuVisible = false; hostWin.editMode = true; editStudioRoot.galleryOpen = true; }
                }
            }
        }
    }

    // ── Bilah Toolbar Edit Atas (Anti-Tumpuk + Smooth Morph) ────────────────
    Rectangle {
        id: editToolbar
        z: 50
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: hostWin.editMode ? 12 : -44
        height: 38
        width: editToolbarRow.implicitWidth + 24
        radius: 19
        color: "#D9181A24"
        border.width: 1.1
        border.color: "#55FFFFFF"
        visible: hostWin.editMode || opacity > 0.01
        enabled: hostWin.editMode
        opacity: hostWin.editMode ? 1.0 : 0.0

        Behavior on anchors.topMargin { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        RowLayout {
            id: editToolbarRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: hostWin.widgetsLocked ? "🔒 Terkunci" : "✥ Geser / Tarik Sudut ◢"
                color: hostWin.widgetsLocked ? "#FFD60A" : "#E5E5EA"
                font.pixelSize: 11
                font.bold: true
            }

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: lockBtnTxt.implicitWidth + 18
                radius: 12
                color: hostWin.widgetsLocked ? "#44FFD60A" : (lockBtnM.containsMouse ? "#38FFFFFF" : "#24FFFFFF")
                border.width: 1
                border.color: hostWin.widgetsLocked ? "#88FFD60A" : "#3CFFFFFF"
                scale: lockBtnM.pressed ? 0.94 : 1.0

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                Text {
                    id: lockBtnTxt; anchors.centerIn: parent
                    text: hostWin.widgetsLocked ? "Buka Kunci" : "Lock"
                    color: ThemeTokens.textPrimary; font.pixelSize: 10; font.bold: true
                }
                MouseArea { id: lockBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.toggleLock() }
            }

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: addWidTxt.implicitWidth + 18
                radius: 12
                color: editStudioRoot.galleryOpen ? ThemeTokens.accent : (addWidM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.inputBg)
                border.width: 1
                border.color: editStudioRoot.galleryOpen ? ThemeTokens.accent : ThemeTokens.borderStrong
                scale: addWidM.pressed ? 0.94 : 1.0

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                Text {
                    id: addWidTxt; anchors.centerIn: parent
                    text: editStudioRoot.galleryOpen ? "Tutup Galeri" : "+ Widget"
                    color: editStudioRoot.galleryOpen ? "#FFFFFF" : "#A1C6FF"
                    font.pixelSize: 10; font.bold: true
                }
                MouseArea { id: addWidM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: editStudioRoot.galleryOpen = !editStudioRoot.galleryOpen }
            }

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 52
                radius: 12
                color: resetBtnM.containsMouse ? "#38FFFFFF" : ThemeTokens.cardHoverBg
                scale: resetBtnM.pressed ? 0.94 : 1.0

                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                Text { anchors.centerIn: parent; text: "Reset"; color: ThemeTokens.textPrimary; font.pixelSize: 10 }
                MouseArea { id: resetBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.resetLayout() }
            }

            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 60
                radius: 12
                color: doneBtnM.containsMouse ? "#2897FF" : "#0A84FF"
                scale: doneBtnM.pressed ? 0.94 : 1.0

                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                Text { anchors.centerIn: parent; text: "Selesai"; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true }
                MouseArea {
                    id: doneBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { editStudioRoot.galleryOpen = false; hostWin.editMode = false; hostWin.saveLayout(); }
                }
            }
        }
    }

    // ── Galeri Home Screen dengan Navigasi Keyboard & Smooth Scrolling ──────
    FocusScope {
        id: homeWidgetDrawer
        z: 48
        anchors.top: editToolbar.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 95
        width: Math.min(parent.width - 290, 668)
        height: 386
        visible: hostWin.editMode && (editStudioRoot.galleryOpen || opacity > 0.01)
        enabled: hostWin.editMode && editStudioRoot.galleryOpen
        opacity: (hostWin.editMode && editStudioRoot.galleryOpen) ? 1.0 : 0.0
        scale: (hostWin.editMode && editStudioRoot.galleryOpen) ? 1.0 : 0.94
        transformOrigin: Item.Top
        focus: editStudioRoot.galleryOpen

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { SpringAnimation { mass: 0.92; spring: 5.8; damping: 0.56; epsilon: 0.001 } }

        Keys.enabled: editStudioRoot.galleryOpen
        Keys.onPressed: (event) => {
            let wps = shellRoot.wallpaperList || [];
            let wids = editStudioRoot.widgetCatalog;

            if (event.key === Qt.Key_Escape) {
                editStudioRoot.galleryOpen = false;
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                editStudioRoot.activeSection = "wallpaper";
                editStudioRoot.scrollToWallpaper(editStudioRoot.selectedWpIndex);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                editStudioRoot.activeSection = "widget";
                editStudioRoot.scrollToWidget(editStudioRoot.selectedWidgetIndex);
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                if (editStudioRoot.activeSection === "wallpaper" && wps.length > 0) {
                    editStudioRoot.selectedWpIndex = Math.max(0, editStudioRoot.selectedWpIndex - 1);
                    editStudioRoot.scrollToWallpaper(editStudioRoot.selectedWpIndex);
                    shellRoot.currentWallpaper = editStudioRoot.imgUri(wps[editStudioRoot.selectedWpIndex]);
                    hostWin.saveLayout();
                } else if (wids.length > 0) {
                    editStudioRoot.activeSection = "widget";
                    editStudioRoot.selectedWidgetIndex = Math.max(0, editStudioRoot.selectedWidgetIndex - 1);
                    editStudioRoot.scrollToWidget(editStudioRoot.selectedWidgetIndex);
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                if (editStudioRoot.activeSection === "wallpaper" && wps.length > 0) {
                    editStudioRoot.selectedWpIndex = Math.min(wps.length - 1, editStudioRoot.selectedWpIndex + 1);
                    editStudioRoot.scrollToWallpaper(editStudioRoot.selectedWpIndex);
                    shellRoot.currentWallpaper = editStudioRoot.imgUri(wps[editStudioRoot.selectedWpIndex]);
                    hostWin.saveLayout();
                } else if (wids.length > 0) {
                    editStudioRoot.activeSection = "widget";
                    editStudioRoot.selectedWidgetIndex = Math.min(wids.length - 1, editStudioRoot.selectedWidgetIndex + 1);
                    editStudioRoot.scrollToWidget(editStudioRoot.selectedWidgetIndex);
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (editStudioRoot.activeSection === "wallpaper" && wps.length > 0) {
                    shellRoot.currentWallpaper = editStudioRoot.imgUri(wps[editStudioRoot.selectedWpIndex]);
                    hostWin.saveLayout();
                } else if (wids.length > 0) {
                    let item = wids[editStudioRoot.selectedWidgetIndex];
                    hostWin.setWidgetEnabled(item.key, !hostWin.isWidgetOn(item.key));
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
                if (editStudioRoot.activeSection === "widget" && wids.length > 0) {
                    let item = wids[editStudioRoot.selectedWidgetIndex];
                    if (hostWin.isWidgetOn(item.key)) {
                        hostWin.setWidgetScale(item.key, hostWin.getWidgetScale(item.key) + 0.1);
                        hostWin.saveLayout();
                    }
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Minus || event.key === Qt.Key_Underscore) {
                if (editStudioRoot.activeSection === "widget" && wids.length > 0) {
                    let item = wids[editStudioRoot.selectedWidgetIndex];
                    if (hostWin.isWidgetOn(item.key)) {
                        hostWin.setWidgetScale(item.key, hostWin.getWidgetScale(item.key) - 0.1);
                        hostWin.saveLayout();
                    }
                }
                event.accepted = true;
            }
        }

        Canvas {
            anchors.fill: parent
            property real dX: homeWidgetDrawer.x
            property real dY: homeWidgetDrawer.y
            property real dO: shellRoot.aeroOpacity
            property real dR: shellRoot.aeroReflection
            property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
            property real dTh: shellRoot.activeGlassDetail
            onDXChanged: requestPaint()
            onDYChanged: requestPaint()
            onDOChanged: requestPaint()
            onDRChanged: requestPaint()
            onDStChanged: requestPaint()
            onDThChanged: requestPaint()
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 24, homeWidgetDrawer.x, homeWidgetDrawer.y, false)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 9

            // ════════════════════════════════════════════════════════════════
            // BAGIAN ATAS: KONTROL WALLPAPER MANDIRI (Navigasi Atas ↑)
            // ════════════════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 86
                radius: 16
                color: editStudioRoot.activeSection === "wallpaper" ? Qt.rgba(ThemeTokens.accent.r, ThemeTokens.accent.g, ThemeTokens.accent.b, 0.14) : "transparent"
                border.width: editStudioRoot.activeSection === "wallpaper" ? 1.2 : 0
                border.color: editStudioRoot.activeSection === "wallpaper" ? ThemeTokens.accent : "transparent"

                Behavior on color { ColorAnimation { duration: 180 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 126
                        Layout.preferredHeight: 74
                        radius: 12
                        clip: true
                        color: ThemeTokens.inputBg
                        border.width: 1.5
                        border.color: ThemeTokens.accent

                        Image {
                            anchors.fill: parent
                            source: editStudioRoot.imgUri(shellRoot.resolvedStaticWallpaper ? shellRoot.resolvedStaticWallpaper(shellRoot.currentWallpaper) : shellRoot.currentWallpaper)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                            height: 18; color: "#A6000000"
                            Text { anchors.centerIn: parent; text: "Wallpaper Aktif"; color: "#FFFFFF"; font.pixelSize: 9; font.bold: true }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Pilih Wallpaper"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                            Text {
                                text: "(" + (shellRoot.wallpaperList ? shellRoot.wallpaperList.length : 0) + ")"
                                color: ThemeTokens.textSecondary; font.pixelSize: 11
                            }
                            Rectangle {
                                visible: editStudioRoot.activeSection === "wallpaper"
                                Layout.preferredHeight: 17
                                Layout.preferredWidth: wpFocusTag.implicitWidth + 10
                                radius: 8.5
                                color: ThemeTokens.accent
                                Text { id: wpFocusTag; anchors.centerIn: parent; text: "Fokus ↑"; color: "#FFFFFF"; font.pixelSize: 9; font.bold: true }
                            }
                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 11; color: ThemeTokens.inputBg
                                Text { anchors.centerIn: parent; text: "‹"; color: ThemeTokens.textPrimary; font.pixelSize: 14; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let wps = shellRoot.wallpaperList || [];
                                        editStudioRoot.activeSection = "wallpaper";
                                        homeWidgetDrawer.forceActiveFocus();
                                        if (wps.length > 0) {
                                            editStudioRoot.selectedWpIndex = Math.max(0, editStudioRoot.selectedWpIndex - 1);
                                            editStudioRoot.scrollToWallpaper(editStudioRoot.selectedWpIndex);
                                            shellRoot.currentWallpaper = editStudioRoot.imgUri(wps[editStudioRoot.selectedWpIndex]);
                                            hostWin.saveLayout();
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 11; color: ThemeTokens.inputBg
                                Text { anchors.centerIn: parent; text: "›"; color: ThemeTokens.textPrimary; font.pixelSize: 14; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let wps = shellRoot.wallpaperList || [];
                                        editStudioRoot.activeSection = "wallpaper";
                                        homeWidgetDrawer.forceActiveFocus();
                                        if (wps.length > 0) {
                                            editStudioRoot.selectedWpIndex = Math.min(wps.length - 1, editStudioRoot.selectedWpIndex + 1);
                                            editStudioRoot.scrollToWallpaper(editStudioRoot.selectedWpIndex);
                                            shellRoot.currentWallpaper = editStudioRoot.imgUri(wps[editStudioRoot.selectedWpIndex]);
                                            hostWin.saveLayout();
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.preferredHeight: 22; Layout.preferredWidth: 22; radius: 11
                                color: closeGalM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.inputBg
                                Text { anchors.centerIn: parent; text: "×"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                                MouseArea { id: closeGalM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: editStudioRoot.galleryOpen = false }
                            }
                        }

                        ListView {
        populate: Transition { NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }
        flickDeceleration: 2400
        maximumFlickVelocity: 2800
                            id: wpStrip
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            orientation: ListView.Horizontal
                            spacing: 7
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: shellRoot.wallpaperList || []

                            NumberAnimation {
                                id: wpScrollAnim
                                target: wpStrip
                                property: "contentX"
                                duration: 310
                                easing.type: Easing.OutCubic
                            }

                            WheelHandler {
                                onWheel: (event) => {
                                    editStudioRoot.activeSection = "wallpaper";
                                    homeWidgetDrawer.forceActiveFocus();
                                    let base = wpScrollAnim.running ? editStudioRoot.targetWpX : wpStrip.contentX;
                                    editStudioRoot.animateWpTo(base - event.angleDelta.y * 1.4);
                                }
                            }

                            delegate: Rectangle {
                                width: 72
                                height: 44
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 9
                                clip: true
                                color: ThemeTokens.inputBg
                                property string uri: editStudioRoot.imgUri(modelData)
                                property bool isCur: editStudioRoot.imgUri(shellRoot.currentWallpaper) === uri
                                property bool isKeySel: (editStudioRoot.activeSection === "wallpaper" && editStudioRoot.selectedWpIndex === index)
                                scale: isKeySel ? 1.06 : 1.0
                                border.width: (isKeySel || isCur) ? 2.2 : 1
                                border.color: isKeySel ? "#FFFFFF" : (isCur ? ThemeTokens.accent : ThemeTokens.borderSubtle)

                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation { duration: 160 } }

                                Image {
                                    anchors.fill: parent
                                    source: parent.uri
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        editStudioRoot.activeSection = "wallpaper";
                                        editStudioRoot.selectedWpIndex = index;
                                        editStudioRoot.scrollToWallpaper(index);
                                        homeWidgetDrawer.forceActiveFocus();
                                        shellRoot.currentWallpaper = parent.uri;
                                        hostWin.saveLayout();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: ThemeTokens.dividerColor }

            // ════════════════════════════════════════════════════════════════
            // BAGIAN BAWAH: GALERI WIDGET MACOS & NIVROS (Navigasi Bawah ↓)
            // ════════════════════════════════════════════════════════════════
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Galeri Widget macOS & NivrOS"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                Rectangle {
                    visible: editStudioRoot.activeSection === "widget"
                    Layout.preferredHeight: 17
                    Layout.preferredWidth: widFocusTag.implicitWidth + 10
                    radius: 8.5
                    color: ThemeTokens.accent
                    Text { id: widFocusTag; anchors.centerIn: parent; text: "Fokus ↓"; color: "#FFFFFF"; font.pixelSize: 9; font.bold: true }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredHeight: 19
                    Layout.preferredWidth: hintTxt.implicitWidth + 14
                    radius: 9.5
                    color: "#66000000"
                    Text {
                        id: hintTxt
                        anchors.centerIn: parent
                        text: "↑↓ Baris • ←→ Geser • Enter Pasang • +/- Ukuran • Esc Tutup"
                        color: "#F2F2F7"
                        font.pixelSize: 9
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 14
                    color: prevWidM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.inputBg
                    border.width: 1; border.color: ThemeTokens.borderSubtle
                    Text { anchors.centerIn: parent; text: "‹"; color: ThemeTokens.textPrimary; font.pixelSize: 16; font.bold: true }
                    MouseArea {
                        id: prevWidM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            editStudioRoot.activeSection = "widget";
                            homeWidgetDrawer.forceActiveFocus();
                            editStudioRoot.selectedWidgetIndex = Math.max(0, editStudioRoot.selectedWidgetIndex - 1);
                            editStudioRoot.scrollToWidget(editStudioRoot.selectedWidgetIndex);
                        }
                    }
                }

                ListView {
        populate: Transition { NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }
        flickDeceleration: 2400
        maximumFlickVelocity: 2800
                    id: widgetCarousel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: 10
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: editStudioRoot.widgetCatalog

                    NumberAnimation {
                        id: widgetScrollAnim
                        target: widgetCarousel
                        property: "contentX"
                        duration: 330
                        easing.type: Easing.OutCubic
                    }

                    WheelHandler {
                        onWheel: (event) => {
                            editStudioRoot.activeSection = "widget";
                            homeWidgetDrawer.forceActiveFocus();
                            let base = widgetScrollAnim.running ? editStudioRoot.targetWidgetX : widgetCarousel.contentX;
                            editStudioRoot.animateWidgetTo(base - event.angleDelta.y * 1.5);
                        }
                    }

                    delegate: Rectangle {
                        width: 172
                        height: widgetCarousel.height - 6
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 16
                        property bool isEnabled: hostWin.isWidgetOn(modelData.key)
                        property bool isKeySel: (editStudioRoot.activeSection === "widget" && editStudioRoot.selectedWidgetIndex === index)
                        scale: isKeySel ? 1.03 : 1.0
                        color: isEnabled ? ThemeTokens.accentSoft : ThemeTokens.cardBg
                        border.width: isKeySel ? 2.2 : 1
                        border.color: isKeySel ? "#FFFFFF" : (isEnabled ? ThemeTokens.accent : ThemeTokens.borderSubtle)

                        Behavior on scale { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        MouseArea {
                            anchors.fill: parent
                            z: 1
                            onClicked: {
                                editStudioRoot.activeSection = "widget";
                                editStudioRoot.selectedWidgetIndex = index;
                                editStudioRoot.scrollToWidget(index);
                                homeWidgetDrawer.forceActiveFocus();
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6
                            z: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.title
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 12
                                color: ThemeTokens.inputBg
                                border.width: 1
                                border.color: ThemeTokens.borderSubtle
                                clip: true

                                Column {
                                    anchors.centerIn: parent; spacing: 3
                                    visible: modelData.key === "calendar"
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(new Date(), "MMMM yyyy"); color: ThemeTokens.accent; font.pixelSize: 9; font.bold: true }
                                    Grid {
                                        columns: 7; spacing: 3
                                        Repeater {
                                            model: 21
                                            Rectangle {
                                                width: 13; height: 11; radius: 3
                                                color: index === 10 ? ThemeTokens.accent : "transparent"
                                                Text { anchors.centerIn: parent; text: String(index + 1); color: index === 10 ? "#FFFFFF" : ThemeTokens.textPrimary; font.pixelSize: 7 }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 3
                                    visible: modelData.key === "worldclock"
                                    RowLayout { width: parent.width; Text { text: "Jakarta"; color: ThemeTokens.textPrimary; font.pixelSize: 9; Layout.fillWidth: true } Text { text: Qt.formatTime(new Date(), "HH:mm"); color: ThemeTokens.accent; font.pixelSize: 9; font.bold: true } }
                                    RowLayout { width: parent.width; Text { text: "Tokyo"; color: ThemeTokens.textSecondary; font.pixelSize: 9; Layout.fillWidth: true } Text { text: "+2j"; color: ThemeTokens.textPrimary; font.pixelSize: 9; font.bold: true } }
                                    RowLayout { width: parent.width; Text { text: "London"; color: ThemeTokens.textSecondary; font.pixelSize: 9; Layout.fillWidth: true } Text { text: "-7j"; color: ThemeTokens.textPrimary; font.pixelSize: 9; font.bold: true } }
                                }

                                Column {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 4
                                    visible: modelData.key === "reminders"
                                    Row { spacing: 5; Rectangle { width: 9; height: 9; radius: 4.5; color: "#FF9F0A" } Text { text: "Cek jadwal"; color: ThemeTokens.textMuted; font.pixelSize: 8; font.strikeout: true } }
                                    Row { spacing: 5; Rectangle { width: 9; height: 9; radius: 4.5; border.width: 1; border.color: "#FF9F0A"; color: "transparent" } Text { text: "Rilis NivrOS"; color: ThemeTokens.textPrimary; font.pixelSize: 8 } }
                                    Row { spacing: 5; Rectangle { width: 9; height: 9; radius: 4.5; border.width: 1; border.color: "#FF9F0A"; color: "transparent" } Text { text: "Setup Niri"; color: ThemeTokens.textPrimary; font.pixelSize: 8 } }
                                }

                                Image {
                                    anchors.fill: parent; anchors.margins: 5
                                    visible: modelData.key === "photo"
                                    source: editStudioRoot.imgUri(shellRoot.resolvedStaticWallpaper ? shellRoot.resolvedStaticWallpaper(shellRoot.currentWallpaper) : shellRoot.currentWallpaper)
                                    fillMode: Image.PreserveAspectCrop
                                }

                                Grid {
                                    anchors.centerIn: parent; columns: 2; spacing: 5
                                    visible: modelData.key === "shortcuts"
                                    Repeater {
                                        model: ["#0A84FF", "#30D158", "#FF9F0A", "#BF5AF2"]
                                        Rectangle { width: 32; height: 22; radius: 6; color: modelData; opacity: 0.85 }
                                    }
                                }

                                Rectangle {
                                    anchors.centerIn: parent; width: 54; height: 54; radius: 27
                                    visible: modelData.key === "analog" || modelData.key === "pomodoro"
                                    color: "transparent"; border.width: 3; border.color: ThemeTokens.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.key === "pomodoro" ? "25:00" : "10:10"
                                        color: ThemeTokens.textPrimary; font.pixelSize: 10; font.bold: true
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent; width: parent.width - 18; spacing: 5
                                    visible: modelData.key === "storage" || modelData.key === "sysmon" || modelData.key === "network"
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.key === "storage" ? "Disk (/)" : (modelData.key === "network" ? "↓ 1.2 MB/s  ↑ 320 KB/s" : ("CPU " + shellRoot.cpuUsagePct + "% • " + shellRoot.cpuTempC + "°C"))
                                        color: ThemeTokens.textPrimary; font.pixelSize: 9; font.bold: true
                                    }
                                    Rectangle {
                                        width: parent.width; height: 6; radius: 3; color: ThemeTokens.cardBg
                                        Rectangle { width: parent.width * 0.45; height: 6; radius: 3; color: ThemeTokens.accent }
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent; width: parent.width - 14; spacing: 2
                                    visible: ["clock", "weather", "battery", "media", "notes", "quote"].indexOf(modelData.key) !== -1
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.key === "clock"   ? Qt.formatTime(new Date(), "HH:mm")
                                            : modelData.key === "weather" ? (shellRoot.weatherTempText || "26°C")
                                            : modelData.key === "battery" ? ((ShellState.batteryPercent >= 0 ? ShellState.batteryPercent : 100) + "%")
                                            : modelData.key === "media"   ? "⏮  ▶  ⏭"
                                            : modelData.key === "quote"   ? "“Focus on flow”"
                                            : "Catatan cepat..."
                                        color: ThemeTokens.accent; font.pixelSize: 13; font.bold: true
                                    }
                                    Text {
                                        width: parent.width; horizontalAlignment: Text.AlignHCenter
                                        text: modelData.sub; color: ThemeTokens.textSecondary; font.pixelSize: 8; elide: Text.ElideRight
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: isEnabled
                                spacing: 4
                                Rectangle {
                                    Layout.preferredWidth: 24; Layout.preferredHeight: 20; radius: 6; color: ThemeTokens.inputBg
                                    Text { anchors.centerIn: parent; text: "−"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            editStudioRoot.activeSection = "widget";
                                            editStudioRoot.selectedWidgetIndex = index;
                                            homeWidgetDrawer.forceActiveFocus();
                                            hostWin.setWidgetScale(modelData.key, hostWin.getWidgetScale(modelData.key) - 0.1);
                                            hostWin.saveLayout();
                                        }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                                    text: Math.round(hostWin.getWidgetScale(modelData.key) * 100) + "%"
                                    color: ThemeTokens.textPrimary; font.pixelSize: 9; font.bold: true
                                }
                                Rectangle {
                                    Layout.preferredWidth: 24; Layout.preferredHeight: 20; radius: 6; color: ThemeTokens.inputBg
                                    Text { anchors.centerIn: parent; text: "+"; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            editStudioRoot.activeSection = "widget";
                                            editStudioRoot.selectedWidgetIndex = index;
                                            homeWidgetDrawer.forceActiveFocus();
                                            hostWin.setWidgetScale(modelData.key, hostWin.getWidgetScale(modelData.key) + 0.1);
                                            hostWin.saveLayout();
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                radius: 13
                                color: isEnabled ? ThemeTokens.cardHoverBg : ThemeTokens.accent
                                border.width: isEnabled ? 1 : 0
                                border.color: ThemeTokens.borderStrong
                                Behavior on color { ColorAnimation { duration: 160 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: isEnabled ? "✓ Terpasang" : "+ Tambah"
                                    color: isEnabled ? ThemeTokens.textPrimary : "#FFFFFF"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        editStudioRoot.activeSection = "widget";
                                        editStudioRoot.selectedWidgetIndex = index;
                                        homeWidgetDrawer.forceActiveFocus();
                                        hostWin.setWidgetEnabled(modelData.key, !isEnabled);
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 14
                    color: nextWidM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.inputBg
                    border.width: 1; border.color: ThemeTokens.borderSubtle
                    Text { anchors.centerIn: parent; text: "›"; color: ThemeTokens.textPrimary; font.pixelSize: 16; font.bold: true }
                    MouseArea {
                        id: nextWidM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            editStudioRoot.activeSection = "widget";
                            homeWidgetDrawer.forceActiveFocus();
                            editStudioRoot.selectedWidgetIndex = Math.min(editStudioRoot.widgetCatalog.length - 1, editStudioRoot.selectedWidgetIndex + 1);
                            editStudioRoot.scrollToWidget(editStudioRoot.selectedWidgetIndex);
                        }
                    }
                }
            }
        }
    }
}
