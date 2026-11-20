//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QT_ICON_THEME=WhiteSur-dark
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import "core"
import "dock"
import "bar"
import "popups"
import "widgets"

ShellRoot {
    id: root

    function formatTime(sec) {
        let s = Math.max(0, Math.floor(sec || 0));
        let m = Math.floor(s / 60);
        let r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    property bool dockWidgetsEnabled: true
    property bool desktopEditMode: false
    property bool dockWidgetEditorOpen: false
    property var cpuHistory: [12, 16, 14, 20, 18, 15, 13, 17, 14, 12]
    property var dockItems: ({
        focus: true,
        calendar: true,
        cpu: true,
        battery: true,
        media: true,
        settings: true
    })
    property var dockLeftOrder: ["focus", "calendar", "cpu", "battery"]
    property var dockRightOrder: ["media", "settings"]

    function isDockWidgetOn(key) {
        return root.dockWidgetsEnabled && root.dockItems && !!root.dockItems[key];
    }

    function toggleDockWidget(key) {
        let next = JSON.parse(JSON.stringify(root.dockItems || { focus: true, calendar: true, cpu: true, battery: true, media: true, settings: true }));
        next[key] = !next[key];
        root.dockItems = next;
        let anyOn = false;
        for (let k in next) {
            if (next[k]) anyOn = true;
        }
        root.dockWidgetsEnabled = anyOn;
        if (typeof win !== "undefined" && win.saveLayout) win.saveLayout();
    }

    function moveDockWidget(side, key, dir) {
        let arr = (side === "left" ? root.dockLeftOrder : root.dockRightOrder).slice();
        let idx = arr.indexOf(key);
        let target = idx + dir;
        if (idx < 0 || target < 0 || target >= arr.length) return;
        let tmp = arr[idx];
        arr[idx] = arr[target];
        arr[target] = tmp;
        if (side === "left") root.dockLeftOrder = arr;
        else root.dockRightOrder = arr;
        if (typeof win !== "undefined" && win.saveLayout) win.saveLayout();
    }

    function setAllDockWidgets(enableAll) {
        root.dockItems = {
            focus: enableAll,
            calendar: enableAll,
            cpu: enableAll,
            battery: enableAll,
            media: enableAll,
            settings: enableAll
        };
        root.dockWidgetsEnabled = enableAll;
        if (typeof win !== "undefined" && win.saveLayout) win.saveLayout();
    }

    function openDockWidgetEditor() {
        if (typeof root.closePopups === "function") root.closePopups();
        if (typeof win !== "undefined") {
            if ("ctxMenuVisible" in win) win.ctxMenuVisible = false;
            win.editMode = false;
        }
        root.desktopEditMode = false;
        root.dockWidgetEditorOpen = true;
    }

    // ── State Animasi Bertahap Seluruh Sistem ───────────────────────────
    property int bootStage: 1
    Timer {
        id: bootStaggerTimer
        interval: 85
        repeat: true
        running: true
        onTriggered: {
            if (root.bootStage < 6) root.bootStage++;
            else stop();
        }
    }

    // ── State Sistem & Hardware Terverifikasi ───────────────────────────
    property var wallpaperList: []
    property string currentWallpaper: ""
    property string defaultWallpaper: ""
    property string wallpaperCycleMode: "gacha" // "gacha" | "next"
    property string wallpaperSourceMode: "sample" // "sample" | "custom"
    property string customWallpaperDir: ""
    property string customWallpaperFile: ""
    property bool liveWallpaperEnabled: false
    property bool pauseWhenUnseen: true
    readonly property bool liveWallpaperPaused: !liveWallpaperEnabled || (pauseWhenUnseen && hasWindowOnActiveWs && activePopup === "")
    property var favoriteWallpapers: []
    property int autoCycleMinutes: 0 // 0 = Off, > 0 = interval dalam menit
    property int autoCycleIntervalSec: autoCycleMinutes * 60
    property string focusedAppName: "Finder"
    property var runningWindows: []
    property bool hasWindowOnActiveWs: false

    property string wifiName: "Memeriksa..."
    property bool wifiEnabled: true
    property bool wifiConnected: false
    property var wifiNetworks: []
    property bool wifiScanning: false
    property string wifiPasswordTarget: ""
    property string wifiStatusMsg: ""

    property bool btEnabled: false
    property string btDeviceName: ""
    property var btDevices: []
    property bool btScanning: false
    property string btBusyMac: ""

    property bool keepAwake: false
    property bool dndEnabled: false

    property int volumeLevel: 60
    property bool volumeMuted: false
    property int brightnessLevel: 80
    property int batteryPercent: -1
    property string batteryStatus: ""

    // ── State Popup Bertahap & Bergantian (Anti-Flicker) ────────────────
    property string activePopup: "" // "", "apple", "window", "desktop", "cc", "wifi", "bt", "music", "calendar", "launchpad", "spotlight"
    property string glassStyle: "mac"
    property string mediaTitle: "No Media"
    property string mediaArtist: "Idle"
    property string mediaArtUrl: ""
    property real mediaPosition: 0
    property real mediaLength: 0
    property bool mediaPlaying: false

    property string weatherCity: "Tulungagung"
    property string weatherTemp: "31°"
    property string weatherDesc: "Partly cloudy"
    property string weatherIcon: "☀"


    function refreshWeather() {
        weatherProc.running = false;
        weatherProc.running = true;
    }

    Process {
        id: mediaProc
        Component.onCompleted: running = true
        command: ["sh", "-c", "playerctl metadata --format '{{status}}\x1f{{title}}\x1f{{artist}}\x1f{{mpris:artUrl}}\x1f{{position}}\x1f{{mpris:length}}' 2>/dev/null || printf 'Stopped\x1fNo Media\x1fIdle\x1f\x1f0\x1f0\n'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = text.trim();
                if (!raw) return;
                let p = raw.split("\x1f");
                root.mediaPlaying = (p[0] === "Playing");
                root.mediaTitle = (p[1] && p[1].trim() !== "") ? p[1].trim() : "No Media";
                root.mediaArtist = (p[2] && p[2].trim() !== "") ? p[2].trim() : (root.mediaPlaying ? "Playing" : "Idle");
                let rawArt = (p[3] && p[3].trim() !== "") ? p[3].trim() : "";
                root.mediaArtUrl = (rawArt.startsWith("file://") || rawArt.startsWith("http://") || rawArt.startsWith("https://")) ? rawArt : "";
                let pos = parseFloat(p[4]) || 0;
                let len = parseFloat(p[5]) || 0;
                if (pos > 100000) pos = pos / 1000000.0;
                if (len > 100000) len = len / 1000000.0;
                root.mediaPosition = pos;
                root.mediaLength = len;
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: { mediaProc.running = false; mediaProc.running = true; }
    }

    Process {
        id: weatherProc
        Component.onCompleted: running = true
        command: ["sh", "-c", "curl -fsS --max-time 6 'https://wttr.in/?format=%l|%t|%C|%c' 2>/dev/null || echo 'Tulungagung|31°|Partly cloudy|☀'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = text.trim();
                if (!raw) return;
                let p = raw.split("|");
                if (p.length >= 4) {
                    if (p[0].trim() !== "") root.weatherCity = p[0].trim().split(",")[0];
                    if (p[1].trim() !== "") root.weatherTemp = p[1].trim().replace("+", "").replace("C", "");
                    if (p[2].trim() !== "") root.weatherDesc = p[2].trim();
                    if (p[3].trim() !== "") root.weatherIcon = p[3].trim();
                }
            }
        }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: root.refreshWeather()
    }
    property var widgetCfg: ({
        locked: false,
        noteText: "Catatan Kairo:
• Cek tugas & riset
• Atur widget dari menu Settings",
        items: {
            media:   { enabled: true,  x: 24,  y: 44 },
            clock:   { enabled: true,  x: 262, y: 44 },
            weather: { enabled: true,  x: 262, y: 204 },
            battery: { enabled: true,  x: 24,  y: 352 },
            sysmon:  { enabled: true,  x: 262, y: 352 },
            notes:   { enabled: false, x: 422, y: 44 }
        }
    })
    property int cpuUsagePct: 12
    property int ramUsagePct: 24
    property string ramUsageText: "3.6 / 15.0 GB"
    property int cpuTempC: 46
    property real macOpacity: 0.33
    property real macFrost: 0.42
    property real aeroBaseOpacity: 0.30
    property real aeroSheenBright: 0.46
    property real aeroSheenWidth: 0.48
    property real liquidOpacity: 0.28
    property real liquidRefraction: 0.64
    property real liquidFringing: 0.45
    property real aeroOpacity: glassStyle === "aero" ? aeroBaseOpacity : (glassStyle === "liquid" ? liquidOpacity : macOpacity)
    property real aeroReflection: glassStyle === "aero" ? aeroSheenBright : (glassStyle === "liquid" ? liquidRefraction : macFrost)
    property real activeGlassDetail: glassStyle === "liquid" ? liquidFringing : aeroSheenWidth

    Item {
        id: coreStateBridge
        Component.onCompleted: {
            ShellState.glassStyle = root.glassStyle;
            ShellState.macOpacity = root.macOpacity;
            ShellState.macFrost = root.macFrost;
            ShellState.aeroBaseOpacity = root.aeroBaseOpacity;
            ShellState.aeroSheenBright = root.aeroSheenBright;
            ShellState.aeroSheenWidth = root.aeroSheenWidth;
            ShellState.liquidOpacity = root.liquidOpacity;
            ShellState.liquidRefraction = root.liquidRefraction;
            ShellState.liquidFringing = root.liquidFringing;
            ShellState.activePopup = root.activePopup;
            ShellState.editMode = root.desktopEditMode;
        ShellState.batteryPercent = root.batteryPercent;
        ShellState.batteryStatus = root.batteryStatus;
        ShellState.bootStage = root.bootStage;
        ShellState.focusedAppName = root.focusedAppName;
        ShellState.musicPreviewVisible = root.musicPreviewVisible;
        ShellState.wifiConnected = root.wifiConnected;
            ShellState.switchPopupHandler = function(name) { root.switchPopup(name); };
            ShellState.runCmdHandler = function(cmd) { root.runCmd(cmd); };
            ShellState.saveLayoutHandler = function() { if (typeof win !== "undefined" && win.saveLayout) win.saveLayout(); };
        }
    
        Connections {
            target: root
            function onGlassStyleChanged() { if (ShellState.glassStyle !== root.glassStyle) ShellState.glassStyle = root.glassStyle; }
            function onMacOpacityChanged() { if (ShellState.macOpacity !== root.macOpacity) ShellState.macOpacity = root.macOpacity; }
            function onMacFrostChanged() { if (ShellState.macFrost !== root.macFrost) ShellState.macFrost = root.macFrost; }
            function onAeroBaseOpacityChanged() { if (ShellState.aeroBaseOpacity !== root.aeroBaseOpacity) ShellState.aeroBaseOpacity = root.aeroBaseOpacity; }
            function onAeroSheenBrightChanged() { if (ShellState.aeroSheenBright !== root.aeroSheenBright) ShellState.aeroSheenBright = root.aeroSheenBright; }
            function onAeroSheenWidthChanged() { if (ShellState.aeroSheenWidth !== root.aeroSheenWidth) ShellState.aeroSheenWidth = root.aeroSheenWidth; }
            function onLiquidOpacityChanged() { if (ShellState.liquidOpacity !== root.liquidOpacity) ShellState.liquidOpacity = root.liquidOpacity; }
            function onLiquidRefractionChanged() { if (ShellState.liquidRefraction !== root.liquidRefraction) ShellState.liquidRefraction = root.liquidRefraction; }
            function onLiquidFringingChanged() { if (ShellState.liquidFringing !== root.liquidFringing) ShellState.liquidFringing = root.liquidFringing; }
            function onActivePopupChanged() { if (ShellState.activePopup !== root.activePopup) ShellState.activePopup = root.activePopup; }
            function onDesktopEditModeChanged() { if (ShellState.editMode !== root.desktopEditMode) ShellState.editMode = root.desktopEditMode; }
        function onBatteryPercentChanged() { if (ShellState.batteryPercent !== root.batteryPercent) ShellState.batteryPercent = root.batteryPercent; }
        function onBatteryStatusChanged() { if (ShellState.batteryStatus !== root.batteryStatus) ShellState.batteryStatus = root.batteryStatus; }
        function onBootStageChanged() { if (ShellState.bootStage !== root.bootStage) ShellState.bootStage = root.bootStage; }
        function onFocusedAppNameChanged() { if (ShellState.focusedAppName !== root.focusedAppName) ShellState.focusedAppName = root.focusedAppName; }
        function onMusicPreviewVisibleChanged() { if (ShellState.musicPreviewVisible !== root.musicPreviewVisible) ShellState.musicPreviewVisible = root.musicPreviewVisible; }
        function onWifiConnectedChanged() { if (ShellState.wifiConnected !== root.wifiConnected) ShellState.wifiConnected = root.wifiConnected; }
        }
    
        Connections {
            target: ShellState
            function onEditModeChanged() {
                if (typeof win !== "undefined" && win.editMode !== ShellState.editMode) {
                    win.editMode = ShellState.editMode;
                }
            }
        }
    }
    property string activeGlassWall: ""
    property string prevGlassWall: ""
    property real glassFade: 1.0

    NumberAnimation {
        id: rootGlassFadeAnim
        target: root
        property: "glassFade"
        from: 0.0
        to: 1.0
        duration: 950
        easing.type: Easing.InOutCubic
    }

    Image {
        id: rootGlassCurImg
        visible: false
        source: root.currentWallpaper
        sourceSize: Qt.size(96, 54)
        smooth: true
        asynchronous: true
        onStatusChanged: {
            if (status === Image.Ready && String(source) !== "" && root.activeGlassWall !== String(source)) {
                root.prevGlassWall = root.activeGlassWall;
                root.activeGlassWall = String(source);
                if (root.prevGlassWall !== "") {
                    root.glassFade = 0.0;
                    rootGlassFadeAnim.restart();
                } else {
                    root.glassFade = 1.0;
                }
            }
        }
    }

    Image {
        id: rootGlassPrevImg
        visible: false
        source: root.prevGlassWall
        sourceSize: Qt.size(96, 54)
        smooth: true
        asynchronous: true
    }

    function drawWallLayerGlobal(ctx, imgItem, offX, offY, scrW, scrH) {
        if (!imgItem || imgItem.status !== Image.Ready || imgItem.implicitWidth <= 0 || imgItem.implicitHeight <= 0) return;
        let iw = imgItem.implicitWidth;
        let ih = imgItem.implicitHeight;
        let sc = Math.max(scrW / iw, scrH / ih);
        let dw = iw * sc;
        let dh = ih * sc;
        let dx = (scrW - dw) * 0.5 - offX;
        let dy = (scrH - dh) * 0.5 - offY;
        ctx.drawImage(imgItem, dx, dy, dw, dh);
    }

    function drawGlobalAeroGlass(ctx, w, h, rad, offX, offY, scrW, scrH, isCircular, drawRim) {
        GlassEngine.drawGlobalAeroGlass(ctx, w, h, rad, offX, offY, scrW, scrH, isCircular, drawRim);
    }
    property string settingsTab: "appearance"
    property string settingsSearch: ""
    property string dockHideMode: "smart" // "smart", "always", "never"
    property string localIpAddr: "127.0.0.1"
    property string powerProfile: "balanced"
    property var sysSpecs: ({
        osName: "Linux",
        kernel: "-",
        hostModel: "ThinkPad",
        userHost: "user@host",
        cpuModel: "AMD Ryzen",
        gpuModel: "AMD Radeon Graphics",
        ramUsed: "0 GiB",
        ramTotal: "0 GiB",
        ramPct: 0,
        diskUsed: "0 GB",
        diskTotal: "0 GB",
        diskPct: 0,
        displayInfo: "1920x1080",
        uptimeStr: "-",
        wmVer: "Niri",
        shellVer: "Quickshell"
    })
    property string copiedBannerMsg: ""
    property var allSystemApps: []
    property string launcherSearchText: ""
    property string queuedPopup: ""
    property bool musicPreviewVisible: false
    property bool niriOverviewActive: false

    Timer {
        id: popupSwitchTimer
        interval: 165
        repeat: false
        onTriggered: {
            root.activePopup = root.queuedPopup;
            root.queuedPopup = "";
            if (root.activePopup === "cc" || root.activePopup === "calendar") {
                sysStatusProc.running = false;
                sysStatusProc.running = true;
            } else if (root.activePopup === "wifi") {
                root.scanWifiNetworks();
            } else if (root.activePopup === "bt") {
                root.scanBtDevices();
            }
        }
    }

    Timer {
        id: deferredPopupRefreshTimer
        interval: 35
        repeat: false
        property string targetPopup: ""
        onTriggered: {
            if (targetPopup === "settings") {
                sysStatusProc.running = false; sysStatusProc.running = true;
                if (typeof settingsExtraProc !== "undefined" && settingsExtraProc) { settingsExtraProc.running = false; settingsExtraProc.running = true; }
                root.scanWifiNetworks();
                root.scanBtDevices();
            } else if (targetPopup === "about") {
                sysStatusProc.running = false; sysStatusProc.running = true;
            } else if (targetPopup === "control" || targetPopup === "cc") {
                sysStatusProc.running = false; sysStatusProc.running = true;
            } else if (targetPopup === "wifi") {
                root.scanWifiNetworks();
            } else if (targetPopup === "bt") {
                root.scanBtDevices();
            }
        }
    }

    property bool preWarmDone: false
    Timer {
        id: preWarmTimer
        interval: 250
        running: true
        repeat: false
        onTriggered: root.preWarmDone = true
    }

    function switchPopup(name) {
        if (root.activePopup === name) {
            root.closePopups();
            return;
        }
        if (name === "settings") root.settingsSearch = "";
        // Langsung picu tampilan visual pada milidetik ke-0 (zero delay)
        root.activePopup = name;
        if (name !== "") {
            deferredPopupRefreshTimer.targetPopup = name;
            deferredPopupRefreshTimer.restart();
        }
    }


    function triggerAppsScan(): void {
        if (typeof allAppsScanProc !== "undefined") { allAppsScanProc.running = false; allAppsScanProc.running = true; }
        if (typeof appsScanProc !== "undefined") {
            appsScanProc.running = false;
            appsScanProc.running = true;
        }
    }

    Timer {
        id: appsSyncTimer
        interval: 60000
        repeat: false
        running: false
        onTriggered: root.triggerAppsScan()
    }

    function closePopups() {
        queuedPopup = "";
        launcherSearchText = "";
        popupSwitchTimer.stop();
        activePopup = "";
        musicPreviewVisible = false;
        wifiPasswordTarget = "";
        wifiStatusMsg = "";
    }

    function formatAppName(rawId) {
        if (!rawId || rawId === "") return "Finder";
        let low = rawId.toLowerCase();
        if (low.includes("nautilus") || low.includes("thunar") || low.includes("dolphin") || low.includes("nemo")) return "Finder";
        if (low.includes("firefox")) return "Firefox";
        if (low.includes("zen")) return "Zen";
        if (low.includes("chrome")) return "Chrome";
        if (low.includes("brave")) return "Brave";
        if (low.includes("alacritty") || low.includes("kitty") || low.includes("foot") || low.includes("wezterm")) return "Terminal";
        if (low.includes("code")) return "VS Code";
        if (low.includes("spotify")) return "Spotify";
        if (low.includes("amberol")) return "Amberol";
        if (low.includes("obsidian")) return "Obsidian";
        if (low.includes("telegram")) return "Telegram";
        if (low.includes("discord") || low.includes("vesktop")) return "Discord";
        if (low.includes("gnome-control-center")) return "Settings";
        let parts = rawId.split(".");
        let last = parts[parts.length - 1];
        return last.charAt(0).toUpperCase() + last.slice(1);
    }

    function pickRandomWallpaper() {
        if (wallpaperList.length === 0) return;
        if (wallpaperList.length === 1) {
            currentWallpaper = wallpaperList[0];
            return;
        }
        let next = currentWallpaper;
        let tries = 0;
        while (next === currentWallpaper && tries < 8) {
            next = wallpaperList[Math.floor(Math.random() * wallpaperList.length)];
            tries++;
        }
        currentWallpaper = next;
    }

    function pickNextWallpaper() {
        if (wallpaperList.length === 0) return;
        let idx = wallpaperList.indexOf(currentWallpaper);
        let nextIdx = (idx + 1) % wallpaperList.length;
        currentWallpaper = wallpaperList[nextIdx];
    }

    function cycleWallpaper() {
        if (wallpaperSourceMode === "custom" && customWallpaperFile.trim() !== "") {
            let p = customWallpaperFile.trim();
            if (!p.startsWith("file://")) p = "file://" + p;
            currentWallpaper = p;
            return;
        }
        if (wallpaperCycleMode === "next") {
            pickNextWallpaper();
        } else {
            pickRandomWallpaper();
        }
    }

    function isFavoriteWallpaper(wp) {
        if (!wp || !favoriteWallpapers) return false;
        return favoriteWallpapers.indexOf(wp) !== -1;
    }

    function toggleFavoriteWallpaper(wp) {
        if (!wp) return;
        let arr = favoriteWallpapers ? favoriteWallpapers.slice() : [];
        let idx = arr.indexOf(wp);
        if (idx === -1) arr.push(wp);
        else arr.splice(idx, 1);
        favoriteWallpapers = arr;
    }

    function resetWallpaperToDefault() {
        wallpaperSourceMode = "sample";
        customWallpaperFile = "";
        customWallpaperDir = "";
        if (defaultWallpaper !== "") {
            currentWallpaper = defaultWallpaper;
        } else if (wallpaperList.length > 0) {
            currentWallpaper = wallpaperList[0];
        }
        reloadWallpapers();
    }

    function activeWallpaperTargetDir() {
        if (wallpaperSourceMode === "custom" && customWallpaperDir.trim() !== "") {
            let d = customWallpaperDir.trim();
            if (d.startsWith("file://")) d = d.slice(7);
            return d;
        }
        return "$HOME/Pictures/Wallpapers";
    }


    function isVideoWallpaperPath(wp) {
        if (!wp) return false;
        let s = String(wp).split("?")[0].toLowerCase();
        return s.endsWith(".mp4") || s.endsWith(".webm") || s.endsWith(".mkv") || s.endsWith(".mov");
    }

    function syncLiveWallpaperProcess() {
        let activeVid = root.liveWallpaperEnabled && root.isVideoWallpaperPath(root.currentWallpaper);
        let shouldPause = !activeVid || root.liveWallpaperPaused;
        let rawPath = String(root.currentWallpaper || "");
        if (rawPath.startsWith("file://")) rawPath = rawPath.slice(7);
        let safePath = rawPath.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "\\$").replace(/`/g, "\\`");

        let cmd = "";
        if (!activeVid) {
            cmd = "pkill -f '[q]s-livewp-mpv' 2>/dev/null || true";
        } else if (shouldPause) {
            cmd = "if pgrep -f '[q]s-livewp-mpv' >/dev/null 2>&1; then "
                + "if command -v socat >/dev/null 2>&1 && [ -S /tmp/qs-livewp.sock ]; then "
                + "printf '{\"command\": [\"set_property\", \"pause\", true]}\n' | socat - /tmp/qs-livewp.sock >/dev/null 2>&1 || true; "
                + "else pkill -STOP -f '[q]s-livewp-mpv' 2>/dev/null || true; fi; fi";
        } else {
            cmd = "if pgrep -f '[q]s-livewp-mpv' >/dev/null 2>&1; then "
                + "if command -v socat >/dev/null 2>&1 && [ -S /tmp/qs-livewp.sock ]; then "
                + "printf '{\"command\": [\"set_property\", \"pause\", false]}\n' | socat - /tmp/qs-livewp.sock >/dev/null 2>&1 || true; "
                + "else pkill -CONT -f '[q]s-livewp-mpv' 2>/dev/null || true; fi; "
                + "elif command -v mpv >/dev/null 2>&1; then "
                + "rm -f /tmp/qs-livewp.sock; "
                + "nohup mpv --no-audio --loop-file=inf --really-quiet --input-ipc-server=/tmp/qs-livewp.sock --title='qs-livewp-mpv' \"" + safePath + "\" >/dev/null 2>&1 & fi";
        }

        liveWpProc.running = false;
        liveWpProc.command = ["sh", "-c", cmd];
        liveWpProc.running = true;
    }
    function reloadWallpapers() {
        let dir = activeWallpaperTargetDir();
        let vidExpr = liveWallpaperEnabled ? " -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov'" : "";
        let cmd = "mkdir -p \"" + dir + "\" 2>/dev/null; find \"" + dir + "\" -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp'" + vidExpr + " \\) 2>/dev/null | sort";
        scanWallProc.running = false;
        scanWallProc.command = ["sh", "-c", cmd];
        scanWallProc.running = true;
    }

    function openWallpaperFolder() {
        let dir = activeWallpaperTargetDir();
        let cmd = "mkdir -p \"" + dir + "\"; (command -v xdg-open >/dev/null 2>&1 && xdg-open \"" + dir + "\") || (command -v thunar >/dev/null 2>&1 && thunar \"" + dir + "\")";
        runCmd(cmd);
    }

    // ── Dedicated Process Runners ───────────────────────────────────────
    Process { id: actionProc }
    Process { id: liveWpProc }
    Process { id: briProc }
    Process { id: volProc }
    Process { id: wifiToggleProc }
    Process { id: btToggleProc }
    Process { id: awakeProc }
    Process { id: dndProc }

    function runCmd(cmd) {
        if (!cmd || cmd.trim() === "") return;
        let clean = cmd.replace(/%[fFuUdDnNickvm]/g, "").trim();
        if (clean.startsWith("niri msg ")) {
            Quickshell.execDetached(["sh", "-c", clean + " >/dev/null 2>&1"]);
        } else {
            Quickshell.execDetached(["sh", "-c", "niri msg action spawn -- sh -c " + JSON.stringify(clean) + " >/dev/null 2>&1 || setsid -f sh -c " + JSON.stringify(clean) + " >/dev/null 2>&1"]);
        }
    }

    function setBrightnessPct(pct) {
        let clamped = Math.max(5, Math.min(100, Math.round(pct)));
        root.brightnessLevel = clamped;
        briProc.running = false;
        briProc.command = ["sh", "-c", "max=$(cat /sys/class/backlight/amdgpu_bl1/max_brightness 2>/dev/null || echo 255); val=$(( " + clamped + " * max / 100 )); if [ -w /sys/class/backlight/amdgpu_bl1/brightness ]; then echo $val > /sys/class/backlight/amdgpu_bl1/brightness; else gdbus call --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1/session/auto --method org.freedesktop.login1.Session.SetBrightness backlight amdgpu_bl1 $val >/dev/null 2>&1; fi"];
        briProc.running = true;
    }

    function setVolumePct(pct) {
        let clamped = Math.max(0, Math.min(100, Math.round(pct)));
        root.volumeLevel = clamped;
        root.volumeMuted = (clamped === 0);
        volProc.running = false;
        volProc.command = ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (clamped / 100).toFixed(2)];
        volProc.running = true;
    }

    function toggleMute() {
        root.volumeMuted = !root.volumeMuted;
        volProc.running = false;
        volProc.command = ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"];
        volProc.running = true;
    }

    function toggleWifi() {
        let next = !root.wifiEnabled;
        root.wifiEnabled = next;
        if (!next) {
            root.wifiConnected = false;
            root.wifiName = "Mati";
            root.wifiNetworks = [];
        } else {
            root.wifiName = "Menghubungkan...";
        }
        wifiToggleProc.running = false;
        wifiToggleProc.command = ["sh", "-c", "LC_ALL=C nmcli radio wifi " + (next ? "on" : "off")];
        wifiToggleProc.running = true;
        refreshTimer.restart();
        if (next && root.activePopup === "wifi") {
            wifiRescanDelay.restart();
        }
    }

    function toggleBluetooth() {
        let next = !root.btEnabled;
        root.btEnabled = next;
        if (!next) {
            root.btDeviceName = "";
            root.btDevices = [];
        }
        btToggleProc.running = false;
        btToggleProc.command = ["sh", "-c", next ? "rfkill unblock bluetooth; LC_ALL=C bluetoothctl power on" : "LC_ALL=C bluetoothctl power off"];
        btToggleProc.running = true;
        refreshTimer.restart();
        if (next && root.activePopup === "bt") {
            btRescanDelay.restart();
        }
    }

    function toggleKeepAwake() {
        let next = !root.keepAwake;
        root.keepAwake = next;
        awakeProc.running = false;
        if (next) {
            awakeProc.command = ["sh", "-c", "systemd-inhibit --what=idle:sleep --who=Quickshell --reason=KeepAwake sleep infinity >/dev/null 2>&1 & echo $! > /tmp/qs-inhibit.pid"];
        } else {
            awakeProc.command = ["sh", "-c", "kill $(cat /tmp/qs-inhibit.pid 2>/dev/null) 2>/dev/null; rm -f /tmp/qs-inhibit.pid"];
        }
        awakeProc.running = true;
    }

    function toggleDnd() {
        let next = !root.dndEnabled;
        root.dndEnabled = next;
        dndProc.running = false;
        dndProc.command = ["sh", "-c", "command -v makoctl >/dev/null && makoctl mode " + (next ? "-a do-not-disturb" : "-r do-not-disturb") + "; command -v swaync-client >/dev/null && swaync-client -d " + (next ? "true" : "false") + "; true"];
        dndProc.running = true;
    }

    // ── Scanner Wi-Fi Sekitar & Koneksi ─────────────────────────────────
    function scanWifiNetworks() {
        if (!root.wifiEnabled) return;
        root.wifiScanning = true;
        wifiListProc.running = false;
        wifiListProc.running = true;
    }

    function connectWifi(ssid, password) {
        root.wifiStatusMsg = "Menghubungkan ke " + ssid + "...";
        wifiConnectProc.running = false;
        if (password && password.length > 0) {
            wifiConnectProc.command = ["sh", "-c", "LC_ALL=C nmcli dev wifi connect \"$1\" password \"$2\" 2>&1", "sh", ssid, password];
        } else {
            wifiConnectProc.command = ["sh", "-c", "LC_ALL=C nmcli dev wifi connect \"$1\" 2>&1", "sh", ssid];
        }
        wifiConnectProc.running = true;
    }

    Process {
        id: wifiListProc
        command: ["sh", "-c", "LC_ALL=C nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan auto 2>/dev/null | awk -F: 'NF>=4 && $2!=\"\" { if (!seen[$2]++ || $1==\"*\") { gsub(/\\|/, \"-\", $2); data[$2]=($1==\"*\"?\"1\":\"0\")\"|\"$2\"|\"$3\"|\"$4 } } END { for (k in data) print data[k] }' | sort -t'|' -k1,1r -k3,3nr | head -n 10"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiScanning = false;
                let lines = text.trim().split("\n").filter(l => l.length > 0);
                let arr = [];
                for (let i = 0; i < lines.length; i++) {
                    let p = lines[i].split("|");
                    if (p.length >= 4) {
                        arr.push({
                            connected: p[0] === "1",
                            ssid: p[1],
                            signal: parseInt(p[2]) || 0,
                            secured: p[3] !== "" && p[3] !== "--"
                        });
                    }
                }
                root.wifiNetworks = arr;
            }
        }
    }

    Process {
        id: wifiConnectProc
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out.toLowerCase().includes("successfully activated") || out.toLowerCase().includes("berhasil")) {
                    root.wifiPasswordTarget = "";
                    root.wifiStatusMsg = "Terhubung";
                    sysStatusProc.running = false;
                    sysStatusProc.running = true;
                    wifiRescanDelay.restart();
                } else {
                    root.wifiStatusMsg = "Perlu kata sandi atau gagal";
                }
            }
        }
    }

    Timer {
        id: wifiRescanDelay
        interval: 1500
        repeat: false
        onTriggered: root.scanWifiNetworks()
    }

    // ── Scanner Bluetooth Tersedia & Koneksi ────────────────────────────
    function scanBtDevices() {
        if (!root.btEnabled) return;
        root.btScanning = true;
        btListProc.running = false;
        btListProc.running = true;
    }

    function toggleBtDevice(mac, currentlyConnected) {
        root.btBusyMac = mac;
        btDevActionProc.running = false;
        btDevActionProc.command = ["sh", "-c", "LC_ALL=C bluetoothctl " + (currentlyConnected ? "disconnect " : "connect ") + mac + " >/dev/null 2>&1"];
        btDevActionProc.running = true;
    }

    Process {
        id: btListProc
        command: ["sh", "-c", "LC_ALL=C; timeout 3 bluetoothctl scan on >/dev/null 2>&1 & bluetoothctl devices 2>/dev/null | while read -r _ mac name; do [ -z \"$mac\" ] && continue; info=$(bluetoothctl info \"$mac\" 2>/dev/null); conn=$(echo \"$info\" | grep -q 'Connected: yes' && echo 1 || echo 0); pair=$(echo \"$info\" | grep -q 'Paired: yes' && echo 1 || echo 0); printf '%s|%s|%s|%s\\n' \"$conn\" \"$pair\" \"$mac\" \"$name\"; done | sort -t'|' -k1,1r -k2,2r | head -n 10"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.btScanning = false;
                let lines = text.trim().split("\n").filter(l => l.length > 0);
                let arr = [];
                for (let i = 0; i < lines.length; i++) {
                    let p = lines[i].split("|");
                    if (p.length >= 4) {
                        arr.push({
                            connected: p[0] === "1",
                            paired: p[1] === "1",
                            mac: p[2],
                            name: p[3] || p[2]
                        });
                    }
                }
                root.btDevices = arr;
            }
        }
    }

    Process {
        id: btDevActionProc
        onExited: {
            root.btBusyMac = "";
            sysStatusProc.running = false;
            sysStatusProc.running = true;
            btRescanDelay.restart();
        }
    }

    Timer {
        id: btRescanDelay
        interval: 1200
        repeat: false
        onTriggered: root.scanBtDevices()
    }

    // ── Proses Pembaca Status Latar Belakang (LC_ALL=C) ─────────────────
    Process {
        id: scanWallProc
        command: ["sh", "-c", "find \"$HOME/Pictures/Wallpapers\" -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n").filter(l => l.length > 0);
                let mapped = lines.map(p => p.startsWith("file://") ? p : "file://" + p);
                if (root.wallpaperSourceMode === "custom" && root.customWallpaperFile.trim() !== "") {
                    let cf = root.customWallpaperFile.trim();
                    if (!cf.startsWith("file://")) cf = "file://" + cf;
                    if (mapped.indexOf(cf) === -1) mapped.unshift(cf);
                }
                root.wallpaperList = mapped;
                if (root.wallpaperList.length > 0 && root.defaultWallpaper === "") {
                    root.defaultWallpaper = root.wallpaperList[0];
                }
                if (root.wallpaperSourceMode === "custom" && root.customWallpaperFile.trim() !== "") {
                    let cf = root.customWallpaperFile.trim();
                    root.currentWallpaper = cf.startsWith("file://") ? cf : "file://" + cf;
                } else if (root.wallpaperList.length > 0 && root.currentWallpaper === "") {
                    root.cycleWallpaper();
                }
            }
        }
    }

    Process {
        id: niriStateProc
        command: ["sh", "-c", "printf 'FOCUS:'; niri msg -j focused-window 2>/dev/null || echo 'null'; printf '\nWS:'; niri msg -j workspaces 2>/dev/null || echo '[]'; printf '\nWINS:'; niri msg -j windows 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                let activeWsId = -1;
                let hasFocusedWin = false;
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("FOCUS:")) {
                        try {
                            let fw = JSON.parse(lines[i].slice(6));
                            hasFocusedWin = !!(fw && fw.id);
                            root.focusedAppName = (fw && fw.app_id) ? root.formatAppName(fw.app_id) : "Finder";
                        } catch (e) {
                            root.focusedAppName = "Finder";
                        }
                    } else if (lines[i].startsWith("WS:")) {
                        try {
                            let wss = JSON.parse(lines[i].slice(3));
                            if (Array.isArray(wss)) {
                                for (let k = 0; k < wss.length; k++) {
                                    if (wss[k].is_focused || wss[k].is_active) {
                                        activeWsId = wss[k].id;
                                        break;
                                    }
                                }
                            }
                        } catch (e) {}
                    } else if (lines[i].startsWith("WINS:")) {
                        try {
                            let ws = JSON.parse(lines[i].slice(5));
                            if (Array.isArray(ws)) {
                                root.runningWindows = ws;
                                if (activeWsId >= 0) {
                                    let found = false;
                                    for (let j = 0; j < ws.length; j++) {
                                        if (ws[j].workspace_id === activeWsId) {
                                            found = true;
                                            break;
                                        }
                                    }
                                    root.hasWindowOnActiveWs = found;
                                } else {
                                    root.hasWindowOnActiveWs = hasFocusedWin || ws.length > 0;
                                }
                            }
                        } catch (e) {}
                    }
                }
            }
        }
    }

    Process {
        id: sysStatusProc
        command: ["sh", "-c", "export LC_ALL=C; wifi_rad=$(nmcli radio wifi 2>/dev/null | tr -d '[:space:]'); wifi_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $2; exit}'); bt_on=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 1 || echo 0); bt_dev=$(bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-); vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); vol=$(echo \"$vol_raw\" | awk '{print int($2*100+0.5)}'); muted=$(echo \"$vol_raw\" | grep -q 'MUTED' && echo 1 || echo 0); cur_b=$(cat /sys/class/backlight/amdgpu_bl1/brightness 2>/dev/null || echo 0); max_b=$(cat /sys/class/backlight/amdgpu_bl1/max_brightness 2>/dev/null || echo 255); bri=$(( max_b > 0 ? (cur_b * 100 + max_b / 2) / max_b : 80 )); bat_c=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo -1); bat_s=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo ''); awake=$([ -f /tmp/qs-inhibit.pid ] && kill -0 $(cat /tmp/qs-inhibit.pid 2>/dev/null) 2>/dev/null && echo 1 || echo 0); printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\\n' \"$wifi_rad\" \"$wifi_ssid\" \"$bt_on\" \"$bt_dev\" \"$vol\" \"$muted\" \"$bri\" \"$bat_c\" \"$bat_s\" \"$awake\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split("|");
                if (p.length >= 10) {
                    root.wifiEnabled = (p[0] === "enabled");
                    root.wifiConnected = (p[1].length > 0);
                    root.wifiName = p[1].length > 0 ? p[1] : (root.wifiEnabled ? "Tidak Terhubung" : "Mati");
                    root.btEnabled = (p[2] === "1");
                    root.btDeviceName = p[3];
                    if (!isNaN(parseInt(p[4]))) root.volumeLevel = Math.max(0, Math.min(100, parseInt(p[4])));
                    root.volumeMuted = (p[5] === "1");
                    if (!isNaN(parseInt(p[6]))) root.brightnessLevel = Math.max(5, Math.min(100, parseInt(p[6])));
                    if (!isNaN(parseInt(p[7]))) root.batteryPercent = parseInt(p[7]);
                    root.batteryStatus = p[8];
                    root.keepAwake = (p[9] === "1");
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1600
        repeat: false
        onTriggered: {
            sysStatusProc.running = false;
            sysStatusProc.running = true;
        }
    }

    Timer {
        id: screenshotDelayTimer
        interval: 220
        repeat: false
        onTriggered: root.runCmd("niri msg action screenshot")
    }

    Component.onCompleted: {
        scanWallProc.running = true;
        root.triggerAppsScan();
        niriStateProc.running = true;
        sysStatusProc.running = true;
    }

    Timer {
        interval: 260
        running: true
        repeat: true
        onTriggered: niriStateProc.running = true
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: sysStatusProc.running = true
    }

    Timer {
        id: wpAutoCycleTimer
        interval: root.autoCycleMinutes > 0 ? root.autoCycleMinutes * 60 * 1000 : 60000
        running: root.autoCycleMinutes > 0 && (!root.pauseWhenUnseen || !root.hasWindowOnActiveWs || root.activePopup !== "")
        repeat: true
        onTriggered: root.cycleWallpaper()
    }

    Connections {
        target: root
        function onAutoCycleMinutesChanged() {
            if (root.autoCycleMinutes > 0) {
                if (wpAutoCycleTimer.running) wpAutoCycleTimer.restart();
            } else {
                wpAutoCycleTimer.stop();
            }
        }
    }

    Connections {
        target: root
        function onCurrentWallpaperChanged() { root.syncLiveWallpaperProcess(); }
        function onLiveWallpaperEnabledChanged() { root.syncLiveWallpaperProcess(); }
        function onLiveWallpaperPausedChanged() { root.syncLiveWallpaperProcess(); }
    }

    IpcHandler {
        target: "wallpaper"
        function next(): void { root.cycleWallpaper(); }
    }

    IpcHandler {
        target: "widget"
        function edit(): void { win.editMode = !win.editMode; }
        function reset(): void { win.resetLayout(); }
        function set(x: real, y: real, scale: real): void {
            win.widgetScale = Math.max(0.55, Math.min(1.8, scale));
            win.posX = Math.max(0, x);
            win.posY = Math.max(36, y);
            win.saveLayout();
        }
    }

    // 1. FULLSCREEN WALLPAPER DENGAN 18 SHADER ANIMASI IRIS
    PanelWindow {
        id: bgWin
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "iris-wallpaper"
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; bottom: true; left: true; right: true }
        color: "#000000"

        WallpaperCrossfader {
            anchors.fill: parent
            source: root.currentWallpaper
            transitionType: "shaderRandom"
            transitionBaseDuration: 950
        }
    }

    // 1B. BACKDROP KHUSUS NIRI OVERVIEW (WALLPAPER FROSTED GLASS BLUR)
    PanelWindow {
        id: overviewBackdropWin
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "iris-overview-backdrop"
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; bottom: true; left: true; right: true }
        color: "#0D1017"

        Image {
            id: overviewWpImg
            anchors.fill: parent
            source: root.currentWallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            scale: 1.05
        }

        MultiEffect {
            anchors.fill: overviewWpImg
            source: overviewWpImg
            blurEnabled: true
            blurMax: 64
            blur: 0.85
            saturation: 0.15
        }

        Rectangle {
            anchors.fill: parent
            color: "#260E121B"
        }
    }

    // 2. MACOS TOP MENU BAR (SMOOTH STAGGERED ENTRANCE + SPRING HOVER)
    TopBar { shellRoot: root }

    // 3. POPUP HOVER PREVIEW MUSIC PLAYER (TENGAH ATAS TANPA KLIK)
    PanelWindow {
        id: musicPreviewWin
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "macos-music-preview"
        exclusionMode: ExclusionMode.Ignore
        visible: (root.musicPreviewVisible && root.activePopup !== "music") || musicPreviewCard.opacity > 0.01

        anchors { top: true }
        margins { top: 32 }
        implicitWidth: 286
        implicitHeight: 82
        color: "transparent"

        property var mediaPlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

        HoverHandler {
            id: musicPreviewHover
            onHoveredChanged: {
                if (hovered) if (typeof musicPreviewCloseTimer !== 'undefined') musicPreviewCloseTimer.stop();
                else if (typeof musicPreviewCloseTimer !== 'undefined') musicPreviewCloseTimer.restart();
            }
        }

        Rectangle {
            id: musicPreviewCard
            anchors.horizontalCenter: parent.horizontalCenter
            width: 278
            height: 72
            radius: 18
            color: "#EB18181E"
            border.width: 1
            border.color: "#38FFFFFF"

            property bool isOpen: root.musicPreviewVisible && root.activePopup !== "music"
            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            y: isOpen ? 0 : -10
            transformOrigin: Item.Top

            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
            Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.72 } }
            Behavior on y { SpringAnimation { spring: 7.5; damping: 0.72 } }

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    width: 52; height: 52; radius: 12
                    color: "#2A2A32"; clip: true

                    Image {
                        id: prevArt
                        anchors.fill: parent
                        source: musicPreviewWin.mediaPlayer ? musicPreviewWin.mediaPlayer.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: "#A1C6FF"
                        font.pixelSize: 20
                        visible: prevArt.status !== Image.Ready
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 192
                    spacing: 3

                    Text {
                        width: 192
                        text: (musicPreviewWin.mediaPlayer && musicPreviewWin.mediaPlayer.trackTitle)
                              ? musicPreviewWin.mediaPlayer.trackTitle : "Tidak Ada Pemutar Aktif"
                        color: "#F5F5F7"
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: 192
                        text: (musicPreviewWin.mediaPlayer && musicPreviewWin.mediaPlayer.trackArtist)
                              ? musicPreviewWin.mediaPlayer.trackArtist : "Klik kapsul untuk membuka kontrol"
                        color: "#AEAEB2"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 192
                        height: 3
                        radius: 1.5
                        color: "#28FFFFFF"

                        Rectangle {
                            width: {
                                let _ = win.tick;
                                return (musicPreviewWin.mediaPlayer && musicPreviewWin.mediaPlayer.length > 0)
                                    ? Math.min(192, 192 * (musicPreviewWin.mediaPlayer.position / musicPreviewWin.mediaPlayer.length)) : 0;
                            }
                            height: 3
                            radius: 1.5
                            color: "#A1C6FF"
                            Behavior on width { NumberAnimation { duration: 145; easing.type: Easing.InOutCubic } }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.musicPreviewVisible = false;
                    root.switchPopup("music");
                }
            }
        }
    }

    // 4. OVERLAY UNIFIED UNTUK SEMUA POPUP + BACKDROP PENUTUP
    PanelWindow {
        id: popupOverlayWin
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "macos-popups-overlay"
        WlrLayershell.keyboardFocus: (root.wifiPasswordTarget !== "" || root.activePopup === "launchpad" || (root.activePopup === "spotlight" || (root.activePopup === "about" || root.activePopup === "settings"))) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        visible: !root.preWarmDone || root.activePopup !== ""
              || (menuPopupsLoader.item && menuPopupsLoader.item.anyVisible)
              || (ccPopupLoader.item && ccPopupLoader.item.anyVisible)
              || (networkPopupsLoader.item && networkPopupsLoader.item.anyVisible)
              || (mediaCalPopupsLoader.item && mediaCalPopupsLoader.item.anyVisible)
              || (launcherPopupLoader.item && launcherPopupLoader.item.anyVisible)
              || (aboutPopupLoader.item && aboutPopupLoader.item.anyVisible)
              || (settingsPopupLoader.item && settingsPopupLoader.item.cardOpacity > 0.01)

        anchors { top: true; bottom: true; left: true; right: true }
        margins { top: 28 }
        color: "transparent"

        property var mediaPlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

        MouseArea {
            id: backdropMouse
            anchors.fill: parent
            z: 0
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.closePopups()
        }

        Loader {
            id: menuPopupsLoader
            anchors.fill: parent
            property bool holdAlive: false
            active: (root.activePopup === "apple" || root.activePopup === "window" || root.activePopup === "desktop") || holdAlive
            onActiveChanged: {
                if (active && !(root.activePopup === "apple" || root.activePopup === "window" || root.activePopup === "desktop")) holdAlive = false;
            }
            Connections {
                target: root
                function onActivePopupChanged() {
                    if ((root.activePopup === "apple" || root.activePopup === "window" || root.activePopup === "desktop")) {
                        menuPopupsHoldTimer.stop();
                        menuPopupsLoader.holdAlive = true;
                    } else if (menuPopupsLoader.active) {
                        menuPopupsHoldTimer.restart();
                    }
                }
            }
            Timer {
                id: menuPopupsHoldTimer
                interval: 620
                repeat: false
                onTriggered: {
                    if (!(root.activePopup === "apple" || root.activePopup === "window" || root.activePopup === "desktop")) {
                        menuPopupsLoader.holdAlive = false;
                    }
                }
            }
            sourceComponent: MenuPopups {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: ccPopupLoader
            anchors.fill: parent
            property bool holdAlive: false
            active: (root.activePopup === "cc") || holdAlive
            onActiveChanged: {
                if (active && !(root.activePopup === "cc")) holdAlive = false;
            }
            Connections {
                target: root
                function onActivePopupChanged() {
                    if ((root.activePopup === "cc")) {
                        ccPopupHoldTimer.stop();
                        ccPopupLoader.holdAlive = true;
                    } else if (ccPopupLoader.active) {
                        ccPopupHoldTimer.restart();
                    }
                }
            }
            Timer {
                id: ccPopupHoldTimer
                interval: 620
                repeat: false
                onTriggered: {
                    if (!(root.activePopup === "cc")) {
                        ccPopupLoader.holdAlive = false;
                    }
                }
            }
            sourceComponent: ControlCenterPopup {
                shellRoot: root
                hostWin: win
                overlay: popupOverlayWin
            }
        }

        Loader {
            id: networkPopupsLoader
            anchors.fill: parent
            property bool holdAlive: false
            active: (root.activePopup === "wifi" || root.activePopup === "bt") || holdAlive
            onActiveChanged: {
                if (active && !(root.activePopup === "wifi" || root.activePopup === "bt")) holdAlive = false;
            }
            Connections {
                target: root
                function onActivePopupChanged() {
                    if ((root.activePopup === "wifi" || root.activePopup === "bt")) {
                        networkPopupsHoldTimer.stop();
                        networkPopupsLoader.holdAlive = true;
                    } else if (networkPopupsLoader.active) {
                        networkPopupsHoldTimer.restart();
                    }
                }
            }
            Timer {
                id: networkPopupsHoldTimer
                interval: 620
                repeat: false
                onTriggered: {
                    if (!(root.activePopup === "wifi" || root.activePopup === "bt")) {
                        networkPopupsLoader.holdAlive = false;
                    }
                }
            }
            sourceComponent: NetworkPopups {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: mediaCalPopupsLoader
            anchors.fill: parent
            property bool holdAlive: false
            active: (root.activePopup === "music" || root.activePopup === "calendar") || holdAlive
            onActiveChanged: {
                if (active && !(root.activePopup === "music" || root.activePopup === "calendar")) holdAlive = false;
            }
            Connections {
                target: root
                function onActivePopupChanged() {
                    if ((root.activePopup === "music" || root.activePopup === "calendar")) {
                        mediaCalPopupsHoldTimer.stop();
                        mediaCalPopupsLoader.holdAlive = true;
                    } else if (mediaCalPopupsLoader.active) {
                        mediaCalPopupsHoldTimer.restart();
                    }
                }
            }
            Timer {
                id: mediaCalPopupsHoldTimer
                interval: 620
                repeat: false
                onTriggered: {
                    if (!(root.activePopup === "music" || root.activePopup === "calendar")) {
                        mediaCalPopupsLoader.holdAlive = false;
                    }
                }
            }
            sourceComponent: MediaCalendarPopups {
                shellRoot: root
                hostWin: win
                overlay: popupOverlayWin
            }
        }

        Loader {
            id: launcherPopupLoader
            anchors.fill: parent
            property bool holdAlive: false
            active: (root.activePopup === "launchpad" || root.activePopup === "spotlight") || holdAlive
            onActiveChanged: {
                if (active && !(root.activePopup === "launchpad" || root.activePopup === "spotlight")) holdAlive = false;
            }
            Connections {
                target: root
                function onActivePopupChanged() {
                    if ((root.activePopup === "launchpad" || root.activePopup === "spotlight")) {
                        launcherPopupHoldTimer.stop();
                        launcherPopupLoader.holdAlive = true;
                    } else if (launcherPopupLoader.active) {
                        launcherPopupHoldTimer.restart();
                    }
                }
            }
            Timer {
                id: launcherPopupHoldTimer
                interval: 620
                repeat: false
                onTriggered: {
                    if (!(root.activePopup === "launchpad" || root.activePopup === "spotlight")) {
                        launcherPopupLoader.holdAlive = false;
                    }
                }
            }
            sourceComponent: LauncherPopup {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: aboutPopupLoader
            anchors.fill: parent
            property bool holdAlive: false
            active: (root.activePopup === "about") || holdAlive
            onActiveChanged: {
                if (active && !(root.activePopup === "about")) holdAlive = false;
            }
            Connections {
                target: root
                function onActivePopupChanged() {
                    if ((root.activePopup === "about")) {
                        aboutPopupHoldTimer.stop();
                        aboutPopupLoader.holdAlive = true;
                    } else if (aboutPopupLoader.active) {
                        aboutPopupHoldTimer.restart();
                    }
                }
            }
            Timer {
                id: aboutPopupHoldTimer
                interval: 620
                repeat: false
                onTriggered: {
                    if (!(root.activePopup === "about")) {
                        aboutPopupLoader.holdAlive = false;
                    }
                }
            }
            sourceComponent: AboutPopup {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: settingsPopupLoader
            anchors.fill: parent
            property bool holdAlive: false
            active: root.activePopup === "settings" || holdAlive
            onActiveChanged: {
                if (active && root.activePopup !== "settings") holdAlive = false;
            }
            Connections {
                target: root
                function onActivePopupChanged() {
                    if (root.activePopup === "settings") {
                        settingsHoldTimer.stop();
                        settingsPopupLoader.holdAlive = true;
                    } else if (settingsPopupLoader.active) {
                        settingsHoldTimer.restart();
                    }
                }
            }
            Timer {
                id: settingsHoldTimer
                interval: 620
                repeat: false
                onTriggered: {
                    if (root.activePopup !== "settings") {
                        settingsPopupLoader.holdAlive = false;
                    }
                }
            }
            sourceComponent: SettingsPopup {
                shellRoot: root
                hostWin: win
            }
        }
    }

    // 5. DESKTOP WIDGETS IRIS (SMOOTH STAGGERED ENTRANCE)
    PanelWindow {
        id: win
        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true
        margins.top: 28
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-widgets"
        WlrLayershell.keyboardFocus: (win.editMode || (notesWidgetLoader.item && notesWidgetLoader.item.noteFocused)) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        property bool editMode: false
        onEditModeChanged: {
            root.desktopEditMode = editMode;
            if (editMode) {
                root.dockWidgetEditorOpen = false;
                if ("ctxMenuVisible" in win) ctxMenuVisible = false;
            }
        }
        property bool ctxMenuVisible: false
        property real ctxMenuX: 0
        property real ctxMenuY: 0

        function openWidgetCtxMenu(mx, my) {
            let maxX = Math.max(20, (win.width || 1366) - 168);
            let maxY = Math.max(20, (win.height || 768) - 130);
            ctxMenuX = Math.max(12, Math.min(maxX, mx));
            ctxMenuY = Math.max(12, Math.min(maxY, my));
            ctxMenuVisible = true;
        }
        property real posX: 24
        property real posY: 44
        property real widgetScale: 1.0
        property real glassOpacity: root.aeroOpacity
        property real glassReflection: root.aeroReflection
        property bool widgetsLocked: root.widgetCfg.locked
        property string quickNoteText: root.widgetCfg.noteText
        property var widgetStates: root.widgetCfg.items

        function defaultItems() {
            return {
                media:   { enabled: true,  x: 24,  y: 44 },
                clock:   { enabled: true,  x: 262, y: 44 },
                weather: { enabled: true,  x: 262, y: 204 },
                battery: { enabled: true,  x: 24,  y: 352 },
                sysmon:  { enabled: true,  x: 262, y: 352 },
                notes:   { enabled: false, x: 422, y: 44 }
            };
        }

        function isWidgetOn(key) {
            return widgetStates && widgetStates[key] ? !!widgetStates[key].enabled : false;
        }

        function getWidgetX(key) {
            let d = defaultItems();
            return widgetStates && widgetStates[key] && typeof widgetStates[key].x === "number" ? widgetStates[key].x : d[key].x;
        }

        function getWidgetY(key) {
            let d = defaultItems();
            return widgetStates && widgetStates[key] && typeof widgetStates[key].y === "number" ? widgetStates[key].y : d[key].y;
        }

        function setWidgetEnabled(key, val) {
            let next = JSON.parse(JSON.stringify(widgetStates));
            if (!next[key]) next[key] = defaultItems()[key];
            next[key].enabled = val;
            widgetStates = next;
            root.widgetCfg.items = next;
            saveLayout();
        }

        function setWidgetPos(key, nx, ny) {
            let maxX = Math.max(40, (win.width || 1366) - 140);
            let maxY = Math.max(40, (win.height || 768) - 120);
            let cx = Math.round(Math.max(8, Math.min(maxX, nx)));
            let cy = Math.round(Math.max(8, Math.min(maxY, ny)));
            let next = JSON.parse(JSON.stringify(widgetStates));
            if (!next[key]) next[key] = defaultItems()[key];
            next[key].x = cx;
            next[key].y = cy;
            widgetStates = next;
            root.widgetCfg.items = next;
        }

        function toggleLock() {
            widgetsLocked = !widgetsLocked;
            root.widgetCfg.locked = widgetsLocked;
            saveLayout();
        }

        function resetLayout() {
            widgetScale = 1.0;
            widgetsLocked = false;
            widgetStates = defaultItems();
            root.widgetCfg.locked = false;
            root.widgetCfg.items = widgetStates;
            saveLayout();
        }

        function syncNiriLiquidGlass() {
            let mode = root.glassStyle;
            let p1 = "0", p2 = "0", p3 = "0", p4 = "0", p5 = "0";
            if (mode === "mac") {
                p1 = String(Number(root.macOpacity.toFixed(2)));
                p2 = String(Number(root.macFrost.toFixed(2)));
            } else if (mode === "aero") {
                p1 = String(Number(root.aeroBaseOpacity.toFixed(2)));
                p2 = String(Number(root.aeroSheenBright.toFixed(2)));
                p3 = String(Number(root.aeroSheenWidth.toFixed(2)));
            } else {
                // Parameter asli zaroutt/Niri-glass: refraction-strength 0.8..3.8, fringing 0.0..1.0, edge-lighting 0.5..1.15
                p1 = String(Number((0.8 + root.liquidRefraction * 3.0).toFixed(2)));
                p2 = String(Number(root.liquidFringing.toFixed(2)));
                p3 = String(Number((0.55 + root.liquidRefraction * 0.60).toFixed(2)));
                p4 = String(Number((0.15 + root.liquidRefraction * 0.35).toFixed(2)));
                p5 = String(Number(root.liquidOpacity.toFixed(2)));
            }
            niriGlassProc.command = [
                "sh", "-c",
                "python3 \"$HOME/.config/quickshell/sync_niri_glass.py\" \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" \"$6\"",
                "sh", mode, p1, p2, p3, p4, p5
            ];
            niriGlassProc.running = false;
            niriGlassProc.running = true;
        }

        Process { id: niriGlassProc }

        function saveLayout() {
            let data = JSON.stringify({
                scale: Number(widgetScale.toFixed(2)),
                locked: widgetsLocked,
                dockWidgetsEnabled: root.dockWidgetsEnabled,
                dockItems: root.dockItems,
                dockLeftOrder: root.dockLeftOrder,
                dockRightOrder: root.dockRightOrder,
                noteText: quickNoteText,
                items: widgetStates,
                glassStyle: root.glassStyle,
                macOpacity: Number(root.macOpacity.toFixed(2)),
                macFrost: Number(root.macFrost.toFixed(2)),
                aeroBaseOpacity: Number(root.aeroBaseOpacity.toFixed(2)),
                aeroSheenBright: Number(root.aeroSheenBright.toFixed(2)),
                aeroSheenWidth: Number(root.aeroSheenWidth.toFixed(2)),
                liquidOpacity: Number(root.liquidOpacity.toFixed(2)),
                liquidRefraction: Number(root.liquidRefraction.toFixed(2)),
                liquidFringing: Number(root.liquidFringing.toFixed(2))
            });
            saveCfgProc.command = ["sh", "-c", "mkdir -p \"$HOME/.config/quickshell\" && printf '%s' \"$1\" > \"$HOME/.config/quickshell/widgets.json\"", "sh", data];
            saveCfgProc.running = true;
            syncNiriLiquidGlass();
        }

        function drawWidgetGlass(ctx, w, h, rad, itemX, itemY, isCircular) {
            let scrW = win.screen ? win.screen.width : 1366;
            let scrH = win.screen ? win.screen.height : 768;
            root.drawGlobalAeroGlass(ctx, w, h, rad, itemX, itemY + 28, scrW, scrH, !!isCircular, true);
        }

        Process { id: saveCfgProc }

        Process {
            id: loadCfgProc
            Component.onCompleted: running = true
            command: ["sh", "-c", "cat \"$HOME/.config/quickshell/widgets.json\" 2>/dev/null || true"]
            stdout: StdioCollector {
                onStreamFinished: {
                    if (!text || text.trim() === "") return;
                    try {
                        let obj = JSON.parse(text.trim());
                        if (typeof obj.scale === "number") win.widgetScale = Math.max(0.65, Math.min(1.5, obj.scale));
                        if (typeof obj.dockWidgetsEnabled === "boolean") root.dockWidgetsEnabled = obj.dockWidgetsEnabled;
                        if (obj.dockItems && typeof obj.dockItems === "object") {
                            let md = { focus: true, calendar: true, cpu: true, battery: true, media: true, settings: true };
                            for (let k in md) { if (typeof obj.dockItems[k] === "boolean") md[k] = obj.dockItems[k]; }
                            root.dockItems = md;
                        }
                        if (Array.isArray(obj.dockLeftOrder) && obj.dockLeftOrder.length === 4) root.dockLeftOrder = obj.dockLeftOrder;
                        if (Array.isArray(obj.dockRightOrder) && obj.dockRightOrder.length === 2) root.dockRightOrder = obj.dockRightOrder;
                        if (typeof obj.locked === "boolean") {
                            win.widgetsLocked = obj.locked;
                            root.widgetCfg.locked = obj.locked;
                        }
                        if (typeof obj.noteText === "string") {
                            win.quickNoteText = obj.noteText;
                            root.widgetCfg.noteText = obj.noteText;
                        }
                        if (obj.items && typeof obj.items === "object") {
                            let merged = win.defaultItems();
                            for (let k in merged) {
                                if (obj.items[k]) {
                                    merged[k].enabled = !!obj.items[k].enabled;
                                    if (typeof obj.items[k].x === "number") merged[k].x = obj.items[k].x;
                                    if (typeof obj.items[k].y === "number") merged[k].y = obj.items[k].y;
                                }
                            }
                            win.widgetStates = merged;
                            root.widgetCfg.items = merged;
                        }
                        if (obj.glassStyle === "mac" || obj.glassStyle === "aero" || obj.glassStyle === "liquid") root.glassStyle = obj.glassStyle;
                        if (typeof obj.liquidOpacity === "number") root.liquidOpacity = Math.max(0.10, Math.min(0.85, obj.liquidOpacity));
                        if (typeof obj.liquidRefraction === "number") root.liquidRefraction = Math.max(0.0, Math.min(1.0, obj.liquidRefraction));
                        if (typeof obj.liquidFringing === "number") root.liquidFringing = Math.max(0.0, Math.min(1.0, obj.liquidFringing));
                        win.syncNiriLiquidGlass();
                        if (typeof obj.macOpacity === "number") root.macOpacity = Math.max(0.10, Math.min(0.85, obj.macOpacity));
                        if (typeof obj.macFrost === "number") root.macFrost = Math.max(0.0, Math.min(1.0, obj.macFrost));
                        if (typeof obj.aeroBaseOpacity === "number") root.aeroBaseOpacity = Math.max(0.10, Math.min(0.85, obj.aeroBaseOpacity));
                        if (typeof obj.aeroSheenBright === "number") root.aeroSheenBright = Math.max(0.0, Math.min(1.0, obj.aeroSheenBright));
                        if (typeof obj.aeroSheenWidth === "number") root.aeroSheenWidth = Math.max(0.08, Math.min(1.0, obj.aeroSheenWidth));
                    } catch (e) {}
                }
            }
        }

        // Monitor CPU, RAM & Suhu Real-Time untuk Widget System Activity
        Process {
            id: sysMonProc
            Component.onCompleted: running = true
            command: ["sh", "-c", "read _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat; sleep 0.25; read _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat; t1=$((u1+n1+s1+i1+w1+q1+sq1)); t2=$((u2+n2+s2+i2+w2+q2+sq2)); dt=$((t2-t1)); di=$((i2-i1)); cpu=0; [ $dt -gt 0 ] && cpu=$(( (dt - di) * 100 / dt )); read mt ma <<< $(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print t, a}' /proc/meminfo); mu=$((mt - ma)); rpct=$(( mu * 100 / mt )); rgib=$(awk -v u=$mu -v t=$mt 'BEGIN{printf \"%.1f / %.1f GB\", u/1048576, t/1048576}'); temp=45; for z in /sys/class/thermal/thermal_zone*/temp; do if [ -r \"$z\" ]; then v=$(cat \"$z\"); [ \"$v\" -gt 1000 ] && v=$((v/1000)); [ \"$v\" -gt 20 ] && [ \"$v\" -lt 115 ] && temp=$v && break; fi; done; printf '%s|%s|%s|%s\n' \"$cpu\" \"$rpct\" \"$rgib\" \"$temp\""]
            stdout: StdioCollector {
                onStreamFinished: {
                    let p = text.trim().split("|");
                    if (p.length >= 4) {
                        root.cpuUsagePct = Math.max(1, Math.min(100, parseInt(p[0]) || 1));
                        root.ramUsagePct = Math.max(1, Math.min(100, parseInt(p[1]) || 1));
                        root.ramUsageText = p[2];
                        root.cpuTempC = parseInt(p[3]) || 45;
                    }
                }
            }
        }

        Timer {
            interval: 3000
            running: win.isWidgetOn("sysmon")
            repeat: true
            onTriggered: { sysMonProc.running = false; sysMonProc.running = true; }
        }

        // Klik kanan area kosong desktop untuk memunculkan menu Atur; klik kiri untuk menutup
        MouseArea {
            anchors.fill: parent
            z: 0
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (m) => {
                if (m.button === Qt.RightButton) {
                    win.openWidgetCtxMenu(m.x, m.y);
                } else {
                    win.ctxMenuVisible = false;
                    if (win.editMode) {
                        win.editMode = false;
                        win.saveLayout();
                    }
                }
            }
        }

        Loader {
            id: editStudioLoader
            anchors.fill: parent
            active: win.editMode || win.ctxMenuVisible
            sourceComponent: EditStudio {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: mediaWidgetLoader
            anchors.fill: parent
            active: win.isWidgetOn("media")
            sourceComponent: MediaWidget {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: clockWidgetLoader
            anchors.fill: parent
            active: win.isWidgetOn("clock")
            sourceComponent: ClockWidget {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: weatherWidgetLoader
            anchors.fill: parent
            active: win.isWidgetOn("weather")
            sourceComponent: WeatherWidget {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: batteryWidgetLoader
            anchors.fill: parent
            active: win.isWidgetOn("battery")
            sourceComponent: BatteryWidget {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: sysmonWidgetLoader
            anchors.fill: parent
            active: win.isWidgetOn("sysmon")
            sourceComponent: SysmonWidget {
                shellRoot: root
                hostWin: win
            }
        }

        // ====================================================================
        // WIDGET 6: CALENDAR & INTERACTIVE QUICK NOTES (BISA LANGSUNG DIISI)
        Loader {
            id: notesWidgetLoader
            anchors.fill: parent
            active: win.isWidgetOn("notes")
            sourceComponent: NotesWidget {
                shellRoot: root
                hostWin: win
            }
        }
    }

    // 6. MACOS FLOATING DOCK (AUTO-HIDE + EVENT-STREAM + REGION MASK)
    // ========================================================================
    Dock { shellRoot: root }







    // ========================================================================
    // PANEL STUDIO KHUSUS: EDIT WIDGET DOCK
    // ========================================================================
    
}
