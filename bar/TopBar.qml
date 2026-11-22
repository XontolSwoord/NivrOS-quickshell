import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import "../core"

PanelWindow {
    id: topBar
    property var shellRoot: null
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "macos-menubar"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 32

    anchors { top: true; left: true; right: true }
    implicitHeight: 112
    color: "transparent"

    property string dateTimeStr: ""

    // Hanya ambil MPRIS player yang benar-benar sedang memutar audio (abaikan tab browser diam seperti WhatsApp)
    readonly property var playingMprisPlayer: {
        let vals = Mpris.players.values;
        for (let i = 0; i < vals.length; i++) {
            if (vals[i] && vals[i].isPlaying) return vals[i];
        }
        return null;
    }
    property var mediaPlayer: playingMprisPlayer
    readonly property bool isPlaying: !!(playingMprisPlayer && playingMprisPlayer.isPlaying)
    readonly property bool dndActive: !!(shellRoot ? shellRoot.dndEnabled : ShellState.dndEnabled)

    // State Dynamic Island (AMOLED Pure Black + macOS 27 Live Activities)
    property bool islandExpandedByHover: false
    property bool islandMediaPinned: false
    property var activeNotif: null
    property string activeNotifApp: ""
    property string activeNotifSummary: ""
    property string activeNotifBody: ""
    property string activeNotifIcon: ""
    property bool activeNotifCritical: false
    property var notifQueue: []
    property bool dndFlashActive: false

    // Live Activity: Quick Focus Timer (klik kanan / tengah di Dynamic Island)
    property int quickTimerTotalSec: 0
    property int quickTimerRemainSec: 0
    readonly property bool quickTimerActive: quickTimerRemainSec > 0

    // Live Activity: OSD Volume / Kecerahan / Charging flash
    property bool osdFlashActive: false
    property string prevBatStatus: ""
    property bool chargeFlashActive: false

    readonly property bool hasNotif: activeNotifSummary !== ""
    readonly property bool hasActiveMedia: topBar.isPlaying
    readonly property bool isRecordingActive: ShellState.isRecording
    readonly property bool musicPopupOpen: (shellRoot ? shellRoot.activePopup : "") === "music"

    readonly property string islandMode: {
        if (hasNotif) return "notif";
        if (!musicPopupOpen && (islandExpandedByHover || islandMediaPinned || ShellState.islandBehaviorMode === "expanded") && hasActiveMedia) return "media";
        if (osdFlashActive) return "osd";
        if (chargeFlashActive) return "charge";
        if (dndFlashActive) return "dnd";
        if (isRecordingActive) return "rec";
        if (hasActiveMedia) return "playing";
        if (quickTimerActive) return "timer";
        return "idle";
    }
    readonly property bool isExpanded: islandMode === "notif" || islandMode === "media"

    readonly property real compactTargetW: {
        if (islandMode === "notif") return 344;
        if (islandMode === "media") return 336;
        if (islandMode === "osd") return 210;
        if (islandMode === "charge") return 194;
        if (islandMode === "dnd") return 184;
        if (islandMode === "rec") return 148;
        if (islandMode === "timer") return 144;
        if (islandMode === "playing") return Math.min(246, Math.max(146, compactIslandRow.implicitWidth + 24));
        return 118; // Idle polos hitam AMOLED murni tanpa ikon/teks
    }
    readonly property real targetWidth: compactTargetW
    readonly property real targetHeight: {
        if (islandMode === "notif") return 76;
        if (islandMode === "media") return 88;
        return 26;
    }
    readonly property real targetY: ShellState.isMergedIsland ? 0 : 4

    function cycleQuickTimer() {
        if (quickTimerRemainSec <= 0) {
            quickTimerTotalSec = 300;
            quickTimerRemainSec = 300;
        } else if (quickTimerTotalSec === 300) {
            quickTimerTotalSec = 900;
            quickTimerRemainSec = 900;
        } else if (quickTimerTotalSec === 900) {
            quickTimerTotalSec = 1500;
            quickTimerRemainSec = 1500;
        } else {
            quickTimerTotalSec = 0;
            quickTimerRemainSec = 0;
        }
    }

    function formatTimerMinSec(sec) {
        let s = Math.max(0, Math.floor(sec));
        let m = Math.floor(s / 60);
        let r = s % 60;
        return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r;
    }

    // Mask Wayland hanya mencakup 3 pil mengambang (kiri, Dynamic Island tengah, kanan)
    mask: Region {
        regions: [
            Region {
                x: leftPill.x
                y: leftPill.y
                width: leftPill.width
                height: leftPill.height
            },
            Region {
                x: Math.max(0, Math.round((topBar.width - topBar.targetWidth) * 0.5 - 8))
                y: 0
                width: Math.min(topBar.width, Math.round(topBar.targetWidth + 16))
                height: Math.min(topBar.height, Math.round(topBar.targetY + topBar.targetHeight + 10))
            },
            Region {
                x: rightPill.x
                y: rightPill.y
                width: rightPill.width
                height: rightPill.height
            }
        ]
    }

    Connections {
        target: ShellState
        function onOsdSeqChanged() {
            if (ShellState.osdKind !== "") {
                topBar.osdFlashActive = true;
                osdFlashTimer.restart();
            }
        }
        function onTestNotifSeqChanged() {
            if (ShellState.testNotifSummary !== "") {
                topBar.showNotification({
                    appName: ShellState.testNotifApp || "NivrOS",
                    summary: ShellState.testNotifSummary,
                    body: ShellState.testNotifBody || "",
                    appIcon: "dialog-information",
                    expireTimeout: Math.max(2000, (ShellState.notifDurationSec || 4) * 1000)
                });
            }
        }
    }

    property string currentBatStat: (topBar.shellRoot ? topBar.shellRoot.batteryStatus : "")
    onCurrentBatStatChanged: {
        if (prevBatStatus !== "" && currentBatStat === "Charging" && prevBatStatus !== "Charging") {
            chargeFlashActive = true;
            chargeFlashTimer.restart();
        }
        prevBatStatus = currentBatStat;
    }

    onDndActiveChanged: {
        dndFlashActive = true;
        dndFlashTimer.restart();
    }

    Timer {
        id: quickTimerTicker
        interval: 1000
        running: topBar.quickTimerActive
        repeat: true
        onTriggered: {
            if (topBar.quickTimerRemainSec > 1) {
                topBar.quickTimerRemainSec -= 1;
            } else {
                topBar.quickTimerRemainSec = 0;
                topBar.quickTimerTotalSec = 0;
            }
        }
    }

    Timer {
        id: osdFlashTimer
        interval: 1500
        repeat: false
        onTriggered: topBar.osdFlashActive = false
    }

    Timer {
        id: chargeFlashTimer
        interval: 2200
        repeat: false
        onTriggered: topBar.chargeFlashActive = false
    }

    Timer {
        id: dndFlashTimer
        interval: 1800
        repeat: false
        onTriggered: topBar.dndFlashActive = false
    }

    Timer {
        id: islandHoverDwellTimer
        interval: 190
        repeat: false
        onTriggered: {
            if (islandHitHover.hovered && !topBar.musicPopupOpen && topBar.hasActiveMedia && ShellState.islandMusicHover && ShellState.islandBehaviorMode !== "compact") {
                topBar.islandExpandedByHover = true;
            }
        }
    }

    Timer {
        id: islandCollapseTimer
        interval: 340
        repeat: false
        onTriggered: {
            if (!islandHitHover.hovered) {
                topBar.islandExpandedByHover = false;
                topBar.islandMediaPinned = false;
            }
        }
    }

    function showNotification(notifObj) {
        if (!notifObj) return;
        let isCrit = (notifObj.urgency === NotificationUrgency.Critical);
        if (topBar.dndActive && !isCrit) {
            return;
        }
        if (topBar.hasNotif) {
            let q = topBar.notifQueue.slice();
            q.push(notifObj);
            if (q.length > 5) q.shift();
            topBar.notifQueue = q;
            return;
        }
        presentNotification(notifObj);
    }

    function presentNotification(notifObj) {
        topBar.activeNotif = notifObj;
        topBar.activeNotifApp = (notifObj.appName && notifObj.appName !== "") ? notifObj.appName : "Notification";
        topBar.activeNotifSummary = (notifObj.summary && notifObj.summary !== "") ? notifObj.summary : topBar.activeNotifApp;
        topBar.activeNotifBody = notifObj.body || "";
        topBar.activeNotifIcon = notifObj.appIcon || notifObj.image || "";
        topBar.activeNotifCritical = (notifObj.urgency === NotificationUrgency.Critical);

        let baseMs = Math.max(2000, Math.min(10000, (ShellState.notifDurationSec || 4) * 1000));
        let timeoutMs = (notifObj.expireTimeout && notifObj.expireTimeout > 0)
                        ? Math.min(12000, Math.max(2000, notifObj.expireTimeout))
                        : (topBar.activeNotifCritical ? Math.max(6000, baseMs) : baseMs);
        notifAutoDismissTimer.hoverExtends = 0;
        notifAutoDismissTimer.interval = timeoutMs;
        notifAutoDismissTimer.restart();
    }

    function dismissCurrentNotif(invokeDismiss) {
        notifAutoDismissTimer.stop();
        if (invokeDismiss && topBar.activeNotif) {
            try { topBar.activeNotif.dismiss(); } catch (e) {}
        }
        topBar.activeNotif = null;
        topBar.activeNotifApp = "";
        topBar.activeNotifSummary = "";
        topBar.activeNotifBody = "";
        topBar.activeNotifIcon = "";
        topBar.activeNotifCritical = false;

        if (topBar.notifQueue.length > 0) {
            let q = topBar.notifQueue.slice();
            let nextObj = q.shift();
            topBar.notifQueue = q;
            nextNotifDelayTimer.pendingObj = nextObj;
            nextNotifDelayTimer.restart();
        }
    }

    Timer {
        id: notifAutoDismissTimer
        interval: 4200
        repeat: false
        property int hoverExtends: 0
        onTriggered: {
            if (islandHitHover.hovered && hoverExtends < 1) {
                hoverExtends += 1;
                notifAutoDismissTimer.interval = 1500;
                notifAutoDismissTimer.restart();
            } else {
                hoverExtends = 0;
                topBar.dismissCurrentNotif(false);
            }
        }
    }

    Timer {
        id: nextNotifDelayTimer
        interval: 200
        repeat: false
        property var pendingObj: null
        onTriggered: {
            if (pendingObj) {
                let obj = pendingObj;
                pendingObj = null;
                topBar.presentNotification(obj);
            }
        }
    }

    NotificationServer {
        id: islandNotifServer
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: false

        onNotification: (notification) => {
            notification.tracked = true;
            topBar.showNotification(notification);
        }
    }

    function updateClock() {
        let d = new Date();
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        let hr = d.getHours();
        let ampm = hr >= 12 ? "PM" : "AM";
        hr = hr % 12;
        if (hr === 0) hr = 12;
        let min = d.getMinutes();
        let minStr = min < 10 ? "0" + min : "" + min;
        dateTimeStr = days[d.getDay()] + " " + months[d.getMonth()] + " " + d.getDate() + "  " + hr + ":" + minStr + " " + ampm;
    }

    Component.onCompleted: updateClock()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: topBar.updateClock()
    }

    Item {
        id: topBarRoot
        anchors.fill: parent
        opacity: (topBar.shellRoot ? topBar.shellRoot.bootStage : 6) >= 1 ? 1.0 : 0.0
        transform: Translate {
            y: (topBar.shellRoot ? topBar.shellRoot.bootStage : 6) >= 1 ? 0 : -32
            Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
        }
        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

        // ============================================================
        // PIL KACA KIRI (TANPA STRIP HITAM PANJANG & TANPA ANGKA 1 2)
        // ============================================================
        Rectangle {
            id: leftPill
            x: 10
            y: 4
            height: 26
            width: leftPillRow.implicitWidth + 12
            radius: 13
            color: ShellState.isSolid ? ThemeTokens.barBg : "transparent"
            border.width: 1
            border.color: ThemeTokens.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10)

            GlassPanel {
                anchors.fill: parent
                radius: 13
                screenX: leftPill.x
                screenY: leftPill.y
                circular: false
                drawRim: true
                visible: !ShellState.isSolid
            }

            Row {
                id: leftPillRow
                anchors.centerIn: parent
                spacing: 3

                // Logo Apple
                Rectangle {
                    width: 26
                    height: 20
                    radius: 10
                    color: ((topBar.shellRoot ? topBar.shellRoot.activePopup : "") === "apple" || logoM.containsMouse) ? ThemeTokens.cardHoverBg : "transparent"
                    scale: logoM.pressed ? 0.92 : (logoM.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                    Image {
                        id: appleLogoImg
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: "../assets/apple-logo.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: false
                    }
                    MultiEffect {
                        anchors.fill: appleLogoImg
                        source: appleLogoImg
                        colorization: 1.0
                        colorizationColor: ThemeTokens.iconTint
                    }

                    MouseArea {
                        id: logoM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("apple")
                    }
                }

                // Nama Aplikasi Aktif (Finder)
                Rectangle {
                    height: 20
                    width: appTitleTxt.implicitWidth + 10
                    radius: 10
                    color: "transparent"

                    Text {
                        id: appTitleTxt
                        anchors.centerIn: parent
                        text: (topBar.shellRoot ? topBar.shellRoot.focusedAppName : "Finder")
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }

                // Menu Jendela
                Rectangle {
                    height: 20
                    width: winMenuTxt.implicitWidth + 12
                    radius: 10
                    color: ((topBar.shellRoot ? topBar.shellRoot.activePopup : "") === "window" || winMenuM.containsMouse) ? ThemeTokens.cardHoverBg : "transparent"
                    scale: winMenuM.pressed ? 0.94 : (winMenuM.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                    Text {
                        id: winMenuTxt
                        anchors.centerIn: parent
                        text: LocaleStrings.menuWindow
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: winMenuM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("window")
                    }
                }

                // Menu Desktop
                Rectangle {
                    height: 20
                    width: deskMenuTxt.implicitWidth + 12
                    radius: 10
                    color: ((topBar.shellRoot ? topBar.shellRoot.activePopup : "") === "desktop" || deskMenuM.containsMouse) ? ThemeTokens.cardHoverBg : "transparent"
                    scale: deskMenuM.pressed ? 0.94 : (deskMenuM.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                    Text {
                        id: deskMenuTxt
                        anchors.centerIn: parent
                        text: LocaleStrings.menuDesktop
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: deskMenuM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("desktop")
                    }
                }
            }
        }

        // ============================================================
        // PIL KACA KANAN (INDIKATOR SISTEM, SPOTLIGHT, CC, & JAM)
        // ============================================================
        Rectangle {
            id: rightPill
            x: Math.max(leftPill.x + leftPill.width + 8, topBarRoot.width - width - 10)
            y: 4
            height: 26
            width: rightPillRow.implicitWidth + 14
            radius: 13
            color: ShellState.isSolid ? ThemeTokens.barBg : "transparent"
            border.width: 1
            border.color: ThemeTokens.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10)

            GlassPanel {
                anchors.fill: parent
                radius: 13
                screenX: rightPill.x
                screenY: rightPill.y
                circular: false
                drawRim: true
                visible: !ShellState.isSolid
            }

            Row {
                id: rightPillRow
                anchors.centerIn: parent
                spacing: 3

                // Baterai
                Rectangle {
                    height: 20
                    width: batRow.implicitWidth + 8
                    radius: 10
                    color: "transparent"
                    visible: (topBar.shellRoot ? topBar.shellRoot.batteryPercent : -1) >= 0

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (topBar.shellRoot ? topBar.shellRoot.batteryPercent : -1) + "%"
                            color: ThemeTokens.textPrimary
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 21
                            height: 11

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 11
                                radius: 3
                                color: "transparent"
                                border.width: 1
                                border.color: ThemeTokens.textSecondary

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(2, Math.round(14 * ((topBar.shellRoot ? topBar.shellRoot.batteryPercent : -1) / 100)))
                                    height: 7
                                    radius: 1.5
                                    color: (topBar.shellRoot ? topBar.shellRoot.batteryStatus : "") === "Charging" ? "#32D74B"
                                         : ((topBar.shellRoot ? topBar.shellRoot.batteryPercent : -1) <= 20 ? "#FF453A" : ThemeTokens.textPrimary)
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: 4
                                radius: 1
                                color: ThemeTokens.textSecondary
                            }
                        }
                    }
                }

                // Wi-Fi
                Rectangle {
                    width: 24
                    height: 20
                    radius: 10
                    color: ((topBar.shellRoot ? topBar.shellRoot.activePopup : "") === "wifi" || wifiTopM.containsMouse) ? ThemeTokens.cardHoverBg : "transparent"
                    scale: wifiTopM.pressed ? 0.92 : (wifiTopM.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                    Canvas {
                        id: topWifiCanvas
                        anchors.centerIn: parent
                        width: 15
                        height: 13
                        property bool active: (topBar.shellRoot ? topBar.shellRoot.wifiConnected : false)
                        property color tintCol: ThemeTokens.iconTint
                        onActiveChanged: requestPaint()
                        onTintColChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = active ? tintCol : Qt.rgba(tintCol.r, tintCol.g, tintCol.b, 0.42);
                            ctx.lineWidth = 1.5;
                            ctx.lineCap = "round";
                            for (let r = 2.8; r <= 8.4; r += 2.8) {
                                ctx.beginPath();
                                ctx.arc(7.5, 10.8, r, -Math.PI * 0.78, -Math.PI * 0.22);
                                ctx.stroke();
                            }
                            ctx.fillStyle = active ? tintCol : Qt.rgba(tintCol.r, tintCol.g, tintCol.b, 0.42);
                            ctx.beginPath();
                            ctx.arc(7.5, 11.1, 1.2, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }

                    MouseArea {
                        id: wifiTopM
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("wifi")
                    }
                }

                // Pintasan ⌘/
                Rectangle {
                    width: 24
                    height: 20
                    radius: 10
                    color: ((topBar.shellRoot ? topBar.shellRoot.activePopup : "") === "keybinds" || kbTopM.containsMouse) ? ThemeTokens.cardHoverBg : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "⌘/"
                        color: ThemeTokens.iconTint
                        font.pixelSize: 10
                        font.bold: true
                    }
                    MouseArea {
                        id: kbTopM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("keybinds")
                    }
                }

                // Spotlight
                Rectangle {
                    width: 24
                    height: 20
                    radius: 10
                    color: spotM.containsMouse ? ThemeTokens.cardHoverBg : "transparent"
                    scale: spotM.pressed ? 0.92 : (spotM.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                    Canvas {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        property color tintCol: ThemeTokens.iconTint
                        onTintColChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = tintCol;
                            ctx.lineWidth = 1.55;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(5.6, 5.6, 4.0, 0, Math.PI * 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(8.7, 8.7);
                            ctx.lineTo(11.8, 11.8);
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        id: spotM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("spotlight")
                    }
                }

                // Control Center
                Rectangle {
                    width: 26
                    height: 20
                    radius: 10
                    color: ((topBar.shellRoot ? topBar.shellRoot.activePopup : "") === "cc" || ccTopM.containsMouse) ? ThemeTokens.cardHoverBg : "transparent"
                    scale: ccTopM.pressed ? 0.92 : (ccTopM.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                    Canvas {
                        anchors.centerIn: parent
                        width: 15
                        height: 13
                        property color tintCol: ThemeTokens.iconTint
                        onTintColChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = tintCol;
                            ctx.fillStyle = tintCol;
                            ctx.lineWidth = 1.15;
                            ctx.beginPath();
                            ctx.roundedRect(1.5, 1.5, 12, 3.8, 1.9, 1.9);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(11.0, 3.4, 1.4, 0, Math.PI * 2);
                            ctx.fill();
                            ctx.beginPath();
                            ctx.roundedRect(1.5, 7.5, 12, 3.8, 1.9, 1.9);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(4.2, 9.4, 1.4, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }

                    MouseArea {
                        id: ccTopM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("cc")
                    }
                }

                // Tanggal & Jam
                Rectangle {
                    height: 20
                    width: clockTxt.implicitWidth + 10
                    radius: 10
                    color: ((topBar.shellRoot ? topBar.shellRoot.activePopup : "") === "calendar" || clockTopM.containsMouse) ? ThemeTokens.cardHoverBg : "transparent"
                    scale: clockTopM.pressed ? 0.94 : (clockTopM.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                    Text {
                        id: clockTxt
                        anchors.centerIn: parent
                        text: topBar.dateTimeStr
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: clockTopM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("calendar")
                    }
                }
            }
        }

        // ============================================================
        // HIT-ZONE STABIL UNTUK DYNAMIC ISLAND
        // ============================================================
        Item {
            id: islandHitArea
            z: 50
            x: dynamicIsland.x - 4
            y: 0
            width: dynamicIsland.width + 8
            height: dynamicIsland.y + dynamicIsland.height + 6

            HoverHandler {
                id: islandHitHover
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onHoveredChanged: {
                    if (hovered) {
                        islandCollapseTimer.stop();
                        if (!topBar.isExpanded && !islandHoverDwellTimer.running) {
                            islandHoverDwellTimer.restart();
                        }
                    } else {
                        islandHoverDwellTimer.stop();
                        islandCollapseTimer.restart();
                    }
                }
            }
        }

        // ============================================================
        // DYNAMIC ISLAND (TETAP DI TENGAH ATAS)
        // ============================================================
        SlimePhysics {
            id: islandSlime
            slimeActive: ShellState.isMergedIsland
            target: topBar.isExpanded ? 1.0 : 0.0
            viscosity: 0.25
            stiffness: 195.0
            damping: 16.5
            maxStretchY: 0.11
        }

        Item {
            id: dynamicIsland
            z: 20
            readonly property bool isNotchMerged: ShellState.isMergedIsland
            visible: ShellState.islandEnabled
            anchors.horizontalCenter: parent.horizontalCenter
            y: topBar.targetY
            width: topBar.targetWidth
            height: isNotchMerged ? (topBar.isExpanded ? topBar.targetHeight : 30) : topBar.targetHeight
            scale: (!topBar.isExpanded && islandHitHover.hovered && !isNotchMerged) ? 1.035 : 1.0
            transformOrigin: Item.Top
            transform: Scale {
                origin.x: dynamicIsland.width * 0.5
                origin.y: 0
                xScale: dynamicIsland.isNotchMerged ? islandSlime.stretchX : 1.0
                yScale: dynamicIsland.isNotchMerged ? islandSlime.stretchY : 1.0
            }

            readonly property real cornerRadius: topBar.isExpanded ? 23 : (isNotchMerged ? 14 : 13)

            Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            Behavior on width { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            Behavior on height { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

            Canvas {
                id: mergedNotchCanvas
                readonly property real fR: 14
                x: -fR
                y: -2
                width: parent.width + fR * 2
                height: parent.height + 2
                visible: dynamicIsland.isNotchMerged
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()
                onPaint: GlassEngine.drawMergedNotch(getContext("2d"), width, height, dynamicIsland.cornerRadius, fR)
            }

            // Latar Hitam Pekat AMOLED Murni (#000000) untuk Mode Melayang
            // Latar Hitam Pekat AMOLED Murni (#000000) untuk Mode Melayang
            Rectangle {
                anchors.fill: parent
                radius: dynamicIsland.cornerRadius
                visible: !dynamicIsland.isNotchMerged
                color: "#000000"
                border.width: 1
                border.color: {
                    if (topBar.islandMode === "notif") return topBar.activeNotifCritical ? "#88FF453A" : "#44FFFFFF";
                    if (topBar.islandMode === "rec") return "#66FF453A";
                    if (topBar.islandMode === "charge") return "#5532D74B";
                    if (topBar.islandMode === "media" || topBar.hasActiveMedia) return "#38FFFFFF";
                    if (topBar.islandMode === "timer") return "#55FF9F0A";
                    if (topBar.islandMode === "dnd") return "#55BF5AF2";
                    return "#1EFFFFFF";
                }
                Behavior on border.color { ColorAnimation { duration: 210; easing.type: Easing.OutCubic } }
            }

            // 1. LAYER COMPACT (IDLE = POLOS HITAM AMOLED TANPA IKON & TEKS)
            Item {
                anchors.fill: parent
                opacity: !topBar.isExpanded ? 1.0 : 0.0
                scale: !topBar.isExpanded ? 1.0 : 0.90
                visible: opacity > 0.01
                enabled: !topBar.isExpanded

                Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                // Live Activity: DND / Focus Flash
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    opacity: topBar.islandMode === "dnd" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Text {
                        id: dndSysIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: "☾"
                        color: topBar.dndActive ? "#D084FF" : "#C7C7CC"
                        font.pixelSize: 11
                        font.bold: true
                        scale: topBar.islandMode === "dnd" ? 1.0 : 0.72
                        rotation: topBar.islandMode === "dnd" ? 0 : -22
                        Behavior on scale { SpringAnimation { mass: 0.85; spring: 6.2; damping: 0.46; epsilon: 0.001 } }
                        Behavior on rotation { SpringAnimation { mass: 0.85; spring: 5.8; damping: 0.48; epsilon: 0.01 } }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: topBar.dndActive ? "Focus On" : "Focus Off"
                        color: "#FFFFFF"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }

                // Live Activity: Charging Flash
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    opacity: topBar.islandMode === "charge" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⚡"
                        color: "#32D74B"
                        font.pixelSize: 11
                        font.bold: true
                        scale: topBar.islandMode === "charge" ? 1.0 : 0.68
                        Behavior on scale { SpringAnimation { mass: 0.82; spring: 6.5; damping: 0.44; epsilon: 0.001 } }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Charging • " + (topBar.shellRoot ? topBar.shellRoot.batteryPercent : 100) + "%"
                        color: "#FFFFFF"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                // Live Activity: OSD Volume / Kecerahan
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    opacity: topBar.islandMode === "osd" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ShellState.osdKind === "brightness" ? "☀" : (ShellState.osdMuted ? "🔇" : "🔊")
                        color: "#FFFFFF"
                        font.pixelSize: 11
                        scale: topBar.islandMode === "osd" ? 1.0 : 0.75
                        Behavior on scale { SpringAnimation { mass: 0.85; spring: 6.2; damping: 0.48; epsilon: 0.001 } }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 104
                        height: 5
                        radius: 2.5
                        color: "#2C2C32"
                        Rectangle {
                            width: parent.width * (ShellState.osdMuted ? 0 : (ShellState.osdValue / 100.0))
                            height: parent.height
                            radius: 2.5
                            color: "#FFFFFF"
                            Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ShellState.osdMuted ? "Mute" : (ShellState.osdValue + "%")
                        color: "#E5E5EA"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                // Live Activity: Screen Recording
                Row {
                    anchors.centerIn: parent
                    spacing: 7
                    opacity: topBar.islandMode === "rec" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: "#FF453A"
                        SequentialAnimation on opacity {
                            running: topBar.islandMode === "rec"
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 550; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 550; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "REC • " + topBar.formatTimerMinSec(ShellState.recordingSeconds)
                        color: "#FFFFFF"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                // Live Activity: Quick Focus Countdown Timer
                Row {
                    anchors.centerIn: parent
                    spacing: 7
                    opacity: topBar.islandMode === "timer" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Canvas {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        property real prog: topBar.quickTimerTotalSec > 0 ? (topBar.quickTimerRemainSec / topBar.quickTimerTotalSec) : 0
                        onProgChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "#3A2A10";
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.arc(7, 7, 5, 0, Math.PI * 2);
                            ctx.stroke();

                            ctx.strokeStyle = "#FF9F0A";
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(7, 7, 5, -Math.PI * 0.5, -Math.PI * 0.5 + Math.PI * 2 * prog);
                            ctx.stroke();
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: topBar.formatTimerMinSec(topBar.quickTimerRemainSec)
                        color: "#FF9F0A"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                // Live Music Playing (Hanya muncul saat musik benar-benar diputar!)
                Row {
                    id: compactIslandRow
                    anchors.centerIn: parent
                    spacing: 7
                    opacity: topBar.islandMode === "playing" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        radius: 7.5
                        color: "#32D74B"
                        clip: true

                        Image {
                            id: compactArt
                            anchors.fill: parent
                            source: (topBar.mediaPlayer && topBar.mediaPlayer.trackArtUrl) ? topBar.mediaPlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            color: "#0A0E0B"
                            font.pixelSize: 9
                            font.bold: true
                            visible: compactArt.status !== Image.Ready
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (topBar.mediaPlayer && topBar.mediaPlayer.trackTitle !== "")
                              ? topBar.mediaPlayer.trackTitle : ""
                        color: "#F5F5F7"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: Math.min(168, implicitWidth)
                    }

                    // Equalizer Audio Animasi 4-Batang (macOS 27 Now Playing)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        height: 11
                        Repeater {
                            model: [
                                { lo: 3, hi: 10, ms: 340 },
                                { lo: 4, hi: 11, ms: 260 },
                                { lo: 3, hi: 9,  ms: 410 },
                                { lo: 5, hi: 11, ms: 290 }
                            ]
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: modelData.lo
                                radius: 1
                                color: "#32D74B"
                                SequentialAnimation on height {
                                    running: topBar.islandMode === "playing"
                                    loops: Animation.Infinite
                                    NumberAnimation { to: modelData.hi; duration: modelData.ms; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: modelData.lo; duration: modelData.ms; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (m) => {
                        islandHoverDwellTimer.stop();
                        if (m.button === Qt.RightButton || m.button === Qt.MiddleButton) {
                            topBar.cycleQuickTimer();
                            return;
                        }
                        if (topBar.isRecordingActive) {
                            ShellState.isRecording = false;
                            (topBar.shellRoot ? topBar.shellRoot.runCmd : ShellState.runCmd)("pkill -INT wf-recorder 2>/dev/null || true");
                            return;
                        }
                        if (topBar.hasActiveMedia || topBar.quickTimerActive) {
                            topBar.islandMediaPinned = !topBar.islandMediaPinned;
                        }
                    }
                }
            }

            // 2. LAYER EXPANDED: NOTIFICATION BANNER
            Item {
                anchors.fill: parent
                opacity: topBar.islandMode === "notif" ? 1.0 : 0.0
                scale: topBar.islandMode === "notif" ? 1.0 : 0.92
                visible: opacity > 0.01
                enabled: topBar.islandMode === "notif"

                Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: topBar.dismissCurrentNotif(true)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 12
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 11

                    Rectangle {
                        id: notifIconBadge
                        readonly property bool isSystemTestNotif: topBar.activeNotifApp === "NivrOS Push" || topBar.activeNotifApp === "NivrOS"
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 14
                        color: topBar.activeNotifCritical ? "#38FF453A" : "#24A1C6FF"
                        scale: (topBar.islandMode === "notif" && isSystemTestNotif) ? 1.0 : (isSystemTestNotif ? 0.82 : 1.0)
                        rotation: (topBar.islandMode === "notif" && isSystemTestNotif) ? 0 : (isSystemTestNotif ? -10 : 0)
                        Behavior on scale { enabled: notifIconBadge.isSystemTestNotif; SpringAnimation { mass: 0.85; spring: 6.0; damping: 0.46; epsilon: 0.001 } }
                        Behavior on rotation { enabled: notifIconBadge.isSystemTestNotif; SpringAnimation { mass: 0.85; spring: 5.8; damping: 0.48; epsilon: 0.01 } }
                        border.width: 1
                        border.color: topBar.activeNotifCritical ? "#66FF453A" : "#38FFFFFF"
                        clip: true

                        Image {
                            id: notifIconImg
                            anchors.fill: parent
                            anchors.margins: status === Image.Ready ? 0 : 8
                            source: {
                                let ic = topBar.activeNotifIcon;
                                if (!ic) return "";
                                if (ic.startsWith("/") || ic.startsWith("file://") || ic.startsWith("image://"))
                                    return ic;
                                return Quickshell.iconPath(ic, true);
                            }
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: topBar.activeNotifCritical ? "!" : "🔔"
                            color: topBar.activeNotifCritical ? "#FF453A" : "#A1C6FF"
                            font.pixelSize: 19
                            font.bold: true
                            visible: notifIconImg.status !== Image.Ready
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: (topBar.activeNotifApp || "NOTIFICATION").toUpperCase()
                                color: topBar.activeNotifCritical ? "#FF6961" : "#64D2FF"
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                height: 14
                                width: qBadgeTxt.implicitWidth + 8
                                radius: 7
                                color: "#28FFFFFF"
                                visible: topBar.notifQueue.length > 0
                                Text {
                                    id: qBadgeTxt
                                    anchors.centerIn: parent
                                    text: "+" + topBar.notifQueue.length
                                    color: "#E5E5EA"
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: topBar.activeNotifSummary
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            Layout.fillWidth: true
                            text: topBar.activeNotifBody !== "" ? topBar.activeNotifBody : "Klik untuk menutup notifikasi"
                            color: "#D1D1D6"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: 12
                        color: notifCloseM.containsMouse ? "#38FFFFFF" : "#1EFFFFFF"
                        scale: notifCloseM.pressed ? 0.90 : (notifCloseM.containsMouse ? 1.06 : 1.0)
                        Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#E5E5EA"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            id: notifCloseM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: topBar.dismissCurrentNotif(true)
                        }
                    }
                }
            }

            // 3. LAYER EXPANDED: LIVE MUSIC PLAYER CONTROLLER
            Item {
                anchors.fill: parent
                opacity: topBar.islandMode === "media" ? 1.0 : 0.0
                scale: topBar.islandMode === "media" ? 1.0 : 0.92
                visible: opacity > 0.01
                enabled: topBar.islandMode === "media"

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton | Qt.MiddleButton
                    onClicked: topBar.cycleQuickTimer()
                }

                Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    anchors.topMargin: 11
                    anchors.bottomMargin: 11
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 62
                        Layout.preferredHeight: 62
                        radius: 15
                        color: "#22242E"
                        border.width: 1
                        border.color: "#38FFFFFF"
                        clip: true

                        Image {
                            id: expArt
                            anchors.fill: parent
                            source: (topBar.mediaPlayer && topBar.mediaPlayer.trackArtUrl) ? topBar.mediaPlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            color: "#A1C6FF"
                            font.pixelSize: 22
                            visible: expArt.status !== Image.Ready
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                topBar.islandMediaPinned = false;
                                topBar.islandExpandedByHover = false;
                                (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("music");
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: (topBar.mediaPlayer && topBar.mediaPlayer.trackTitle !== "")
                                      ? topBar.mediaPlayer.trackTitle : "Tidak Ada Media"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 10
                                color: openFullMedM.containsMouse ? "#38FFFFFF" : "#1EFFFFFF"
                                scale: openFullMedM.pressed ? 0.90 : (openFullMedM.containsMouse ? 1.06 : 1.0)
                                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "⤢"
                                    color: "#A1C6FF"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                                MouseArea {
                                    id: openFullMedM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        topBar.islandMediaPinned = false;
                                        topBar.islandExpandedByHover = false;
                                        (topBar.shellRoot ? topBar.shellRoot.switchPopup : ShellState.switchPopup)("music");
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (topBar.mediaPlayer && topBar.mediaPlayer.trackArtist !== "")
                                  ? topBar.mediaPlayer.trackArtist : "Pemutar media standby"
                            color: "#D1D1D6"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 3
                            radius: 1.5
                            color: "#28FFFFFF"

                            Rectangle {
                                width: (topBar.mediaPlayer && topBar.mediaPlayer.length > 0)
                                       ? Math.min(parent.width, parent.width * (topBar.mediaPlayer.position / topBar.mediaPlayer.length))
                                       : 0
                                height: 3
                                radius: 1.5
                                color: topBar.isPlaying ? "#32D74B" : "#A1C6FF"
                                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: prevBtnM.containsMouse ? "#2CFFFFFF" : "transparent"
                                scale: prevBtnM.pressed ? 0.88 : (prevBtnM.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
                                Text { anchors.centerIn: parent; text: "⏮"; color: "#F5F5F7"; font.pixelSize: 12 }
                                MouseArea {
                                    id: prevBtnM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (topBar.mediaPlayer && topBar.mediaPlayer.canGoPrevious) topBar.mediaPlayer.previous();
                                        else (topBar.shellRoot ? topBar.shellRoot.runCmd : ShellState.runCmd)("playerctl previous");
                                    }
                                }
                            }

                            Rectangle {
                                width: 28; height: 24; radius: 12
                                color: playBtnM.containsMouse ? "#42FFFFFF" : "#26FFFFFF"
                                scale: playBtnM.pressed ? 0.88 : (playBtnM.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: topBar.isPlaying ? "⏸" : "▶"
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                MouseArea {
                                    id: playBtnM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (topBar.mediaPlayer && topBar.mediaPlayer.canTogglePlaying) topBar.mediaPlayer.togglePlaying();
                                        else (topBar.shellRoot ? topBar.shellRoot.runCmd : ShellState.runCmd)("playerctl play-pause");
                                    }
                                }
                            }

                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: nextBtnM.containsMouse ? "#2CFFFFFF" : "transparent"
                                scale: nextBtnM.pressed ? 0.88 : (nextBtnM.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
                                Text { anchors.centerIn: parent; text: "⏭"; color: "#F5F5F7"; font.pixelSize: 12 }
                                MouseArea {
                                    id: nextBtnM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (topBar.mediaPlayer && topBar.mediaPlayer.canGoNext) topBar.mediaPlayer.next();
                                        else (topBar.shellRoot ? topBar.shellRoot.runCmd : ShellState.runCmd)("playerctl next");
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }
}
