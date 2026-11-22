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
    
    Process {
        id: iconMapLoadProc
        running: true
        command: ["sh", "-c", "cat ~/.config/quickshell/icon_map.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    ShellState.iconMap = JSON.parse(text.trim() || "{}");
                } catch (e) {}
            }
        }
    }

    Process {
        id: profileLoadProc
        running: true
        command: ["sh", "-c", "cat ~/.config/quickshell/profile.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let obj = JSON.parse(text.trim() || "{}");
                    if (obj.name) ShellState.profileName = String(obj.name);
                    if (obj.avatar !== undefined) ShellState.profileAvatar = String(obj.avatar);
                    if (obj.language === "id" || obj.language === "en") ShellState.setLanguage(obj.language);
                    if (obj.surfaceMode === "solid" || obj.surfaceMode === "liquid") ShellState.surfaceMode = obj.surfaceMode;
                    if (obj.liquidVariant === "mac" || obj.liquidVariant === "aero" || obj.liquidVariant === "liquid") ShellState.liquidVariant = obj.liquidVariant;
                    if (obj.colorScheme === "dark" || obj.colorScheme === "light") ShellState.colorScheme = obj.colorScheme;
                    if (obj.islandLayoutMode === "floating" || obj.islandLayoutMode === "merged") ShellState.setIslandLayoutMode(obj.islandLayoutMode);
                    if (typeof obj.islandEnabled === "boolean") ShellState.islandEnabled = obj.islandEnabled;
                    if (typeof obj.islandMusicHover === "boolean") ShellState.islandMusicHover = obj.islandMusicHover;
                    if (obj.islandBehaviorMode === "compact" || obj.islandBehaviorMode === "adaptive" || obj.islandBehaviorMode === "expanded") ShellState.islandBehaviorMode = obj.islandBehaviorMode;
                    if (typeof obj.notifDurationSec === "number") ShellState.notifDurationSec = obj.notifDurationSec;
                    if (obj.recAudioMode === "none" || obj.recAudioMode === "system" || obj.recAudioMode === "sys_mic") ShellState.recAudioMode = obj.recAudioMode;
                    if (["native","360","720","1080","1440","2160"].indexOf(String(obj.recResolution)) !== -1) ShellState.recResolution = String(obj.recResolution);
                } catch (e) {}
            }
        }
    }

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
    property bool sessionLocked: false

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
    property string surfaceMode: "liquid"        // "solid" | "liquid"
    property string liquidVariant: "liquid"         // "mac" | "aero" | "liquid"
    property string colorScheme: "dark"          // "dark" | "light"
    property string chromeLayoutMode: "floating" // "floating" | "merged"
    property string glassStyle: "mac"
    onLiquidVariantChanged: {
        if (liquidVariant === "mac" || liquidVariant === "aero" || liquidVariant === "liquid") {
            if (glassStyle !== liquidVariant) glassStyle = liquidVariant;
        }
    }
    onGlassStyleChanged: {
        if ((glassStyle === "mac" || glassStyle === "aero" || glassStyle === "liquid") && liquidVariant !== glassStyle) {
            liquidVariant = glassStyle;
        }
    }
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
        noteText: "Catatan NivrOS:
• Cek tugas & riset
• Atur widget dari menu Settings",
        items: {
            media:   { enabled: true,  x: 24,  y: 44 },
            clock:   { enabled: true,  x: 262, y: 44 },
            weather: { enabled: true,  x: 262, y: 204 },
                calendar: { enabled: true, x: 24,  y: 204 },
            battery: { enabled: true,  x: 24,  y: 352 },
            sysmon:  { enabled: true,  x: 262, y: 352 },
            notes:   { enabled: false, x: 422, y: 44 }
        }
    })
    property int cpuUsagePct: 12
    property int ramUsagePct: 24
    property string ramUsageText: "3.6 / 15.0 GB"
    property int cpuTempC: 46
    property real macOpacity: 0.41
    property real macFrost: 0.09
    property real aeroBaseOpacity: 0.42
    property real aeroSheenBright: 0.12
    property real aeroSheenWidth: 0.58
    property real liquidOpacity: 0.18
    property real liquidRefraction: 0.79
    property real liquidFringing: 0.41
    property real aeroOpacity: surfaceMode === "solid" ? 1.0 : (liquidVariant === "aero" ? aeroBaseOpacity : (liquidVariant === "liquid" ? liquidOpacity : macOpacity))
    property real aeroReflection: surfaceMode === "solid" ? 0.0 : (liquidVariant === "aero" ? aeroSheenBright : (liquidVariant === "liquid" ? liquidRefraction : macFrost))
    property real activeGlassDetail: surfaceMode === "solid" ? 0.0 : (liquidVariant === "liquid" ? liquidFringing : aeroSheenWidth)

    Item {
        id: coreStateBridge
        Component.onCompleted: {
            ShellState.surfaceMode = root.surfaceMode;
            ShellState.liquidVariant = root.liquidVariant;
            ShellState.colorScheme = root.colorScheme;
            ShellState.chromeLayoutMode = root.chromeLayoutMode;
            ShellState.glassStyle = root.glassStyle;
            ShellState.dockHideMode = root.dockHideMode;
            ShellState.dndEnabled = root.dndEnabled;
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

        Timer {
            id: liveGlassSyncTimer
            interval: 75
            repeat: false
            onTriggered: if (typeof win !== "undefined" && win.syncNiriLiquidGlass) win.syncNiriLiquidGlass()
        }

        Connections {
            target: root
            function onSurfaceModeChanged() { if (ShellState.surfaceMode !== root.surfaceMode) ShellState.surfaceMode = root.surfaceMode; liveGlassSyncTimer.restart(); }
            function onLiquidVariantChanged() { if (ShellState.liquidVariant !== root.liquidVariant) ShellState.liquidVariant = root.liquidVariant; liveGlassSyncTimer.restart(); }
            function onColorSchemeChanged() { if (ShellState.colorScheme !== root.colorScheme) ShellState.colorScheme = root.colorScheme; liveGlassSyncTimer.restart(); }
            function onMacOpacityChanged() { ShellState.macOpacity = root.macOpacity; liveGlassSyncTimer.restart(); }
            function onMacFrostChanged() { ShellState.macFrost = root.macFrost; liveGlassSyncTimer.restart(); }
            function onAeroBaseOpacityChanged() { ShellState.aeroBaseOpacity = root.aeroBaseOpacity; liveGlassSyncTimer.restart(); }
            function onAeroSheenBrightChanged() { ShellState.aeroSheenBright = root.aeroSheenBright; liveGlassSyncTimer.restart(); }
            function onAeroSheenWidthChanged() { ShellState.aeroSheenWidth = root.aeroSheenWidth; liveGlassSyncTimer.restart(); }
            function onLiquidOpacityChanged() { ShellState.liquidOpacity = root.liquidOpacity; liveGlassSyncTimer.restart(); }
            function onLiquidRefractionChanged() { ShellState.liquidRefraction = root.liquidRefraction; liveGlassSyncTimer.restart(); }
            function onLiquidFringingChanged() { ShellState.liquidFringing = root.liquidFringing; liveGlassSyncTimer.restart(); }
        }

        Connections {
            target: ShellState
            function onSurfaceModeChanged() { if (root.surfaceMode !== ShellState.surfaceMode) root.surfaceMode = ShellState.surfaceMode; }
            function onLiquidVariantChanged() { if (root.liquidVariant !== ShellState.liquidVariant) root.liquidVariant = ShellState.liquidVariant; }
            function onColorSchemeChanged() { if (root.colorScheme !== ShellState.colorScheme) root.colorScheme = root.colorScheme; }
        }
    }


    // ── Helper Night Light, Screen Capture/Record, Adaptive Accent, & Niri Workspaces ──
    function applyNightLight() {
        runCmd("pkill -x wlsunset 2>/dev/null; pkill -x gammastep 2>/dev/null; true");
        if (ShellState.nightLightEnabled) {
            let t = ShellState.nightLightTemp || 4200;
            runCmd("nohup wlsunset -t " + t + " -T " + (t + 100) + " >/dev/null 2>&1 || nohup gammastep -O " + t + " >/dev/null 2>&1 &");
        }
    }

    function toggleNightLight() {
        ShellState.nightLightEnabled = !ShellState.nightLightEnabled;
        applyNightLight();
    }

    function captureFullscreen() {
        runCmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/NivrOS_$(date +%Y%m%d_%H%M%S).png && notify-send 'NivrOS Capture' 'Tangkapan layar penuh disimpan'");
    }

    Timer {
        id: recSecondsTicker
        interval: 1000
        running: ShellState.isRecording
        repeat: true
        onTriggered: ShellState.recordingSeconds += 1
    }

    function toggleScreenRecord() {
        if (ShellState.isRecording) {
            runCmd("pkill -INT -x wf-recorder 2>/dev/null || pkill -INT -x wl-screenrec 2>/dev/null");
            ShellState.isRecording = false;
            runCmd("notify-send 'NivrOS Screen Recorder' 'Rekaman layar disimpan ke ~/Videos'");
        } else {
            ShellState.recordingSeconds = 0;
            ShellState.isRecording = true;
            runCmd("nohup ~/.config/quickshell/scripts/nivros_record.sh " + ShellState.recAudioMode + " " + ShellState.recResolution + " >/tmp/nivros_rec.log 2>&1 &");
        }
    }

    function focusNiriWorkspace(idx) {
        runCmd("niri msg action focus-workspace " + idx);
        niriWsPollProc.running = true;
    }

        Process {
        id: accentExtractProc
        property string targetPath: ""
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/extract_accent.py", targetPath]
        stdout: StdioCollector {
            onStreamFinished: {
                let hex = text.trim();
                if (hex.startsWith("#") && hex.length === 7) {
                    ShellState.extractedAccent = hex;
                }
            }
        }
    }

    function extractWallpaperAccent() {
        let wp = String(root.currentWallpaper || "").trim();
        if (wp.startsWith("file://")) wp = decodeURIComponent(wp.slice(7));
        if (wp !== "") {
            accentExtractProc.targetPath = wp;
            accentExtractProc.running = false;
            accentExtractProc.running = true;
        }
    }

    onCurrentWallpaperChanged: {
        if (ShellState.adaptiveAccent) extractWallpaperAccent();
    }

    Process {
        id: niriWsPollProc
        running: true
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/niri_workspaces.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let arr = JSON.parse(text.trim() || "[]");
                    if (arr.length > 0) ShellState.niriWorkspaces = arr;
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 900
        running: true
        repeat: true
        onTriggered: niriWsPollProc.running = true
    }

    readonly property string activeGlassWall: root.currentWallpaper
    readonly property real glassFade: 1.0

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

    property bool menuModalActive: false

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
        command: ["sh", "-c", "primary=\"$HOME/Pictures/Wallpapers $HOME/Wallpapers\"; [ -n \"$CUSTOM_WALL_DIR\" ] && primary=\"$CUSTOM_WALL_DIR $primary\"; found=\"\"; for d in $primary; do if [ -d \"$d\" ]; then out=$(find \"$d\" -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null); [ -n \"$out\" ] && found=\"$found\n$out\"; fi; done; if [ -z \"$(echo \"$found\" | tr -d '[:space:]')\" ]; then for fb in /usr/share/backgrounds /usr/share/wallpapers; do [ -d \"$fb\" ] && find \"$fb\" -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null; done; else printf '%s\n' \"$found\"; fi | sed '/^$/d' | awk '!seen[$0]++' | sort"]
        environment: ({ "CUSTOM_WALL_DIR": root.customWallpaperDir || "" })
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

    property int activeWorkspaceId: -1
    property bool shuttingDownShell: false

    function recomputeActiveWsOccupancy() {
        let ws = root.runningWindows || [];
        if (root.activeWorkspaceId >= 0) {
            root.hasWindowOnActiveWs = ws.some(w => w.workspace_id === root.activeWorkspaceId);
        } else {
            root.hasWindowOnActiveWs = ws.some(w => w.is_focused);
        }
    }

    Process {
        id: niriEventStreamProc
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                let s = line.trim();
                if (!s) return;
                try {
                    let ev = JSON.parse(s);
                    if (ev.WorkspacesChanged && Array.isArray(ev.WorkspacesChanged.workspaces)) {
                        let wss = ev.WorkspacesChanged.workspaces;
                        for (let i = 0; i < wss.length; i++) {
                            if (wss[i].is_focused || wss[i].is_active) {
                                root.activeWorkspaceId = wss[i].id;
                                break;
                            }
                        }
                        root.recomputeActiveWsOccupancy();
                    } else if (ev.WorkspaceActivated && typeof ev.WorkspaceActivated.id === "number") {
                        if (ev.WorkspaceActivated.focused) {
                            root.activeWorkspaceId = ev.WorkspaceActivated.id;
                            root.recomputeActiveWsOccupancy();
                        }
                    } else if (ev.WindowsChanged && Array.isArray(ev.WindowsChanged.windows)) {
                        root.runningWindows = ev.WindowsChanged.windows;
                        let foc = root.runningWindows.find(w => w.is_focused);
                        root.focusedAppName = (foc && foc.app_id) ? root.formatAppName(foc.app_id) : "Finder";
                        root.recomputeActiveWsOccupancy();
                    } else if (ev.WindowOpenedOrChanged && ev.WindowOpenedOrChanged.window) {
                        let w = ev.WindowOpenedOrChanged.window;
                        let next = root.runningWindows.filter(item => item.id !== w.id);
                        if (w.is_focused) {
                            next = next.map(item => Object.assign({}, item, { is_focused: false }));
                            root.focusedAppName = w.app_id ? root.formatAppName(w.app_id) : "Finder";
                        }
                        next.push(w);
                        root.runningWindows = next;
                        root.recomputeActiveWsOccupancy();
                    } else if (ev.WindowClosed && typeof ev.WindowClosed.id === "number") {
                        let closedId = ev.WindowClosed.id;
                        root.runningWindows = root.runningWindows.filter(item => item.id !== closedId);
                        let foc = root.runningWindows.find(w => w.is_focused);
                        root.focusedAppName = (foc && foc.app_id) ? root.formatAppName(foc.app_id) : "Finder";
                        root.recomputeActiveWsOccupancy();
                    } else if (ev.WindowFocusChanged) {
                        let fid = ev.WindowFocusChanged.id;
                        let next = root.runningWindows.map(w => Object.assign({}, w, { is_focused: w.id === fid }));
                        root.runningWindows = next;
                        let foc = next.find(w => w.id === fid);
                        root.focusedAppName = (foc && foc.app_id) ? root.formatAppName(foc.app_id) : "Finder";
                        root.recomputeActiveWsOccupancy();
                    } else if ((ev.OverviewOpenedOrClosed || ev.OverviewOpenedOrChanged) && typeof (ev.OverviewOpenedOrClosed || ev.OverviewOpenedOrChanged).is_open === "boolean") {
                        root.niriOverviewActive = (ev.OverviewOpenedOrClosed || ev.OverviewOpenedOrChanged).is_open;
                    }
                } catch (e) {}
            }
        }
        onExited: {
            if (!root.shuttingDownShell) niriStreamRestartTimer.restart();
        }
    }

    Timer {
        id: niriStreamRestartTimer
        interval: 1500
        repeat: false
        onTriggered: if (!root.shuttingDownShell) niriEventStreamProc.running = true
    }

    Component.onDestruction: {
        root.shuttingDownShell = true;
        niriStreamRestartTimer.stop();
        niriEventStreamProc.running = false;
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
        sysStatusProc.running = true;
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
        running: root.autoCycleMinutes > 0
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
        target: "shell"
        function toggleKeybinds(): void {
            root.switchPopup("keybinds");
        }
    }

    IpcHandler {
        target: "wallpaper"
        function next(): void { root.cycleWallpaper(); }
    }

    IpcHandler {
        target: "lockscreen"
        function lock(): void { root.sessionLocked = true; }
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
        color: "transparent"

        property real cornerRadius: root.niriOverviewActive ? 22 : 0
        Behavior on cornerRadius {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        WallpaperCrossfader {
            id: bgCrossfader
            anchors.fill: parent
            opacity: bgMaskEffect.visible ? 0.0 : 1.0
            source: root.currentWallpaper
            transitionType: "shaderRandom"
            transitionBaseDuration: 950
        }

        Item {
            id: bgMaskSource
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle {
                anchors.fill: parent
                radius: bgWin.cornerRadius
                color: "#FFFFFF"
            }
        }

        MultiEffect {
            id: bgMaskEffect
            anchors.fill: parent
            source: bgCrossfader
            visible: bgWin.cornerRadius > 0.5
            maskEnabled: true
            maskSource: bgMaskSource
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Rectangle {
            anchors.fill: parent
            radius: bgWin.cornerRadius
            color: "transparent"
            border.width: bgWin.cornerRadius > 0.5 ? 1 : 0
            border.color: "#33FFFFFF"
            visible: bgWin.cornerRadius > 0.5
        }
    }

    // 1B. BACKDROP KHUSUS NIRI OVERVIEW (WALLPAPER FROSTED GLASS BLUR)
    PanelWindow {
        id: overviewBackdropWin
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "iris-overview-backdrop"
        exclusionMode: ExclusionMode.Ignore
        visible: true

        anchors { top: true; bottom: true; left: true; right: true }
        color: "#0D1017"

        readonly property string resolvedBgSource: {
            let src = String(root.currentWallpaper || "");
            let low = src.split("?")[0].toLowerCase();
            if (low.endsWith(".mp4") || low.endsWith(".webm") || low.endsWith(".mkv") || low.endsWith(".mov")) {
                for (let i = 0; i < root.wallpaperList.length; i++) {
                    let cand = String(root.wallpaperList[i] || "");
                    let cl = cand.split("?")[0].toLowerCase();
                    if (!cl.endsWith(".mp4") && !cl.endsWith(".webm") && !cl.endsWith(".mkv") && !cl.endsWith(".mov")) {
                        return cand;
                    }
                }
                return "";
            }
            return src;
        }

        Image {
            id: overviewWpImg
            anchors.fill: parent
            source: overviewBackdropWin.resolvedBgSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: overviewWpImg
            visible: overviewWpImg.status === Image.Ready
            blurEnabled: true
            blur: 0.88
            blurMax: 56
            saturation: 0.16
            contrast: -0.04
        }

        // Lapisan tint kaca halus yang sinkron dengan mode Glass Engine aktif
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: root.glassStyle === "liquid"
                        ? Qt.rgba(0.08, 0.11, 0.16, 0.28)
                        : Qt.rgba(0.06, 0.08, 0.12, Math.max(0.24, Math.min(0.46, root.aeroOpacity * 0.85)))
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0.04, 0.05, 0.08, 0.42)
                }
            }
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
        visible: false // Digantikan oleh Dynamic Island di bar/TopBar.qml

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
        WlrLayershell.keyboardFocus: (root.wifiPasswordTarget !== "" || root.activePopup === "launchpad" || (root.activePopup === "spotlight" || ((root.activePopup === "about" || root.activePopup === "keybinds") || root.activePopup === "settings"))) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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

        Rectangle {
            id: backdropHitSurface
            anchors.fill: parent
            z: 0
            color: Qt.rgba(0, 0, 0, 0.002)
            visible: root.activePopup !== "" && !root.menuModalActive

            MouseArea {
                id: backdropMouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPressed: root.closePopups()
            }
        }

        Loader {
            id: menuPopupsLoader
            anchors.fill: parent
            property bool holdAlive: false
            active: (root.activePopup === "apple" || root.activePopup === "window" || root.activePopup === "desktop") || holdAlive || root.menuModalActive
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
            active: ((root.activePopup === "about" || root.activePopup === "keybinds")) || holdAlive
            onActiveChanged: {
                if (active && !((root.activePopup === "about" || root.activePopup === "keybinds"))) holdAlive = false;
            }
            Connections {
                target: root
                function onActivePopupChanged() {
                    if (((root.activePopup === "about" || root.activePopup === "keybinds"))) {
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
                    if (!((root.activePopup === "about" || root.activePopup === "keybinds"))) {
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
        WlrLayershell.keyboardFocus: widgetGalleryOpen ? WlrKeyboardFocus.Exclusive : ((win.editMode || (notesWidgetLoader.item && notesWidgetLoader.item.noteFocused)) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
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
        property bool widgetGalleryOpen: false
        property real widgetScale: 1.0
        property real glassOpacity: root.aeroOpacity
        property real glassReflection: root.aeroReflection
        property bool widgetsLocked: root.widgetCfg.locked
        property string quickNoteText: root.widgetCfg.noteText
        property var widgetStates: root.widgetCfg.items

        function defaultItems() {
            return {
                media:      { enabled: true,  x: 24,  y: 44,  scale: 1.0 },
                sysmon:     { enabled: true,  x: 24,  y: 376, scale: 1.0 },
                clock:      { enabled: true,  x: 274, y: 64,  scale: 1.0 },
                calendar:   { enabled: false, x: 274, y: 256, scale: 1.0 },
                weather:    { enabled: false, x: 520, y: 44,  scale: 1.0 },
                battery:    { enabled: false, x: 520, y: 214, scale: 1.0 },
                notes:      { enabled: false, x: 520, y: 376, scale: 1.0 },
                analog:     { enabled: false, x: 766, y: 44,  scale: 1.0 },
                storage:    { enabled: false, x: 766, y: 232, scale: 1.0 },
                network:    { enabled: false, x: 766, y: 344, scale: 1.0 },
                pomodoro:   { enabled: false, x: 766, y: 432, scale: 1.0 },
                quote:      { enabled: false, x: 274, y: 468, scale: 1.0 },
                worldclock: { enabled: false, x: 520, y: 44,  scale: 1.0 },
                reminders:  { enabled: false, x: 520, y: 226, scale: 1.0 },
                photo:      { enabled: false, x: 766, y: 44,  scale: 1.0 },
                shortcuts:  { enabled: false, x: 766, y: 248, scale: 1.0 }
            };
        }

        property string focusedWidgetKey: ""
        readonly property var widgetBaseSizes: ({
            clock: [226, 146], media: [226, 312], sysmon: [226, 142],
            calendar: [226, 196], weather: [226, 150], battery: [226, 142],
            notes: [226, 176], analog: [186, 186], storage: [226, 98],
            network: [226, 76], pomodoro: [186, 186], quote: [226, 118],
            worldclock: [226, 166], reminders: [226, 148], photo: [186, 186],
            shortcuts: [186, 142]
        })

        function bringWidgetToFront(key) {
            focusedWidgetKey = key;
        }

        function rectsOverlap(x1, y1, w1, h1, x2, y2, w2, h2, pad) {
            return (x1 - pad < x2 + w2) && (x1 + w1 + pad > x2) &&
                   (y1 - pad < y2 + h2) && (y1 + h1 + pad > y2);
        }

        function findFreeWidgetPos(targetKey, prefX, prefY) {
            let base = widgetBaseSizes[targetKey] || [226, 150];
            let sc = getWidgetScale(targetKey);
            let tw = base[0] * sc;
            let th = base[1] * sc;
            let minX = 24;
            let maxX = Math.max(240, (win.width > 0 ? win.width : 1920) - tw - 24);
            let minY = 44;
            let maxY = Math.max(220, (win.height > 0 ? win.height : 1080) - th - 92);

            let items = (root.widgetCfg && root.widgetCfg.items) ? root.widgetCfg.items : {};
            let isSpotFree = function(cx, cy) {
                if (cx < minX || cx > maxX || cy < minY || cy > maxY) return false;
                for (let k in items) {
                    if (k !== targetKey && isWidgetOn(k)) {
                        let ox = getWidgetX(k);
                        let oy = getWidgetY(k);
                        let ob = widgetBaseSizes[k] || [226, 150];
                        let osc = getWidgetScale(k);
                        if (rectsOverlap(cx, cy, tw, th, ox, oy, ob[0] * osc, ob[1] * osc, 16)) {
                            return false;
                        }
                    }
                }
                return true;
            };

            if (isSpotFree(prefX, prefY)) return { x: prefX, y: prefY };

            for (let colX = minX; colX <= maxX; colX += 246) {
                for (let rowY = minY; rowY <= maxY; rowY += 24) {
                    if (isSpotFree(colX, rowY)) return { x: colX, y: rowY };
                }
            }

            let activeCount = 0;
            for (let k in items) { if (isWidgetOn(k)) activeCount++; }
            return {
                x: Math.min(maxX, minX + (activeCount % 6) * 28),
                y: Math.min(maxY, minY + (activeCount % 6) * 28)
            };
        }

        function isWidgetOn(key) {
            return widgetStates && widgetStates[key] ? !!widgetStates[key].enabled : false;
        }

        function getWidgetX(key) {
            let d = defaultItems();
            return widgetStates && widgetStates[key] && typeof widgetStates[key].x === "number" ? widgetStates[key].x : (d[key] ? d[key].x : 24);
        }

        function getWidgetY(key) {
            let d = defaultItems();
            return widgetStates && widgetStates[key] && typeof widgetStates[key].y === "number" ? widgetStates[key].y : (d[key] ? d[key].y : 44);
        }

        function getWidgetScale(key) {
            if (widgetStates && widgetStates[key] && typeof widgetStates[key].scale === "number") {
                return widgetStates[key].scale;
            }
            return widgetScale || 1.0;
        }

        function setWidgetScale(key, sc) {
            let clamped = Number(Math.max(0.65, Math.min(1.75, sc)).toFixed(2));
            let next = JSON.parse(JSON.stringify(widgetStates));
            if (!next[key]) next[key] = defaultItems()[key] || { enabled: true, x: 24, y: 44, scale: 1.0 };
            next[key].scale = clamped;
            widgetStates = next;
            root.widgetCfg.items = next;
        }
        function setWidgetEnabled(key, val) {
            if (val) {
                let freeSlot = findFreeWidgetPos(key, getWidgetX(key), getWidgetY(key));
                setWidgetPos(key, freeSlot.x, freeSlot.y);
                bringWidgetToFront(key);
            }
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
            let mode = (root.surfaceMode === "solid") ? "solid" : root.liquidVariant;
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
                "python3 \"$HOME/.config/quickshell/sync_niri_glass.py\" \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" \"$6\" \"$7\"",
                "sh", mode, p1, p2, p3, p4, p5, root.colorScheme
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
                dockHideMode: root.dockHideMode,
                wallpaperCycleMode: root.wallpaperCycleMode,
                autoCycleMinutes: root.autoCycleMinutes,
                favoriteWallpapers: root.favoriteWallpapers,
                liveWallpaperEnabled: root.liveWallpaperEnabled,
                pauseWhenUnseen: root.pauseWhenUnseen,
                noteText: quickNoteText,
                items: widgetStates,
                surfaceMode: root.surfaceMode,
                liquidVariant: root.liquidVariant,
                colorScheme: root.colorScheme,
                chromeLayoutMode: root.chromeLayoutMode,
                glassStyle: root.liquidVariant,
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
                        if (obj.dockHideMode === "smart" || obj.dockHideMode === "always" || obj.dockHideMode === "never") root.dockHideMode = obj.dockHideMode;
                        if (obj.wallpaperCycleMode === "gacha" || obj.wallpaperCycleMode === "next") root.wallpaperCycleMode = obj.wallpaperCycleMode;
                        if (typeof obj.autoCycleMinutes === "number") root.autoCycleMinutes = Math.max(0, Math.min(1440, obj.autoCycleMinutes));
                        if (Array.isArray(obj.favoriteWallpapers)) root.favoriteWallpapers = obj.favoriteWallpapers;
                        if (typeof obj.liveWallpaperEnabled === "boolean") root.liveWallpaperEnabled = obj.liveWallpaperEnabled;
                        if (typeof obj.pauseWhenUnseen === "boolean") root.pauseWhenUnseen = obj.pauseWhenUnseen;
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
                                    if (typeof obj.items[k].scale === "number") merged[k].scale = Math.max(0.65, Math.min(1.75, obj.items[k].scale));
                                }
                            }
                            win.widgetStates = merged;
                            root.widgetCfg.items = merged;
                        }
                        if (obj.glassStyle === "mac" || obj.glassStyle === "aero" || obj.glassStyle === "liquid") {
                            root.glassStyle = obj.glassStyle;
                            root.liquidVariant = obj.glassStyle;
                        }
                        if (obj.surfaceMode === "solid" || obj.surfaceMode === "liquid") root.surfaceMode = obj.surfaceMode;
                        if (obj.liquidVariant === "mac" || obj.liquidVariant === "aero" || obj.liquidVariant === "liquid") {
                            root.liquidVariant = obj.liquidVariant;
                            root.glassStyle = obj.liquidVariant;
                        }
                        if (obj.colorScheme === "dark" || obj.colorScheme === "light") root.colorScheme = obj.colorScheme;
                        if (obj.chromeLayoutMode === "floating" || obj.chromeLayoutMode === "merged") root.chromeLayoutMode = obj.chromeLayoutMode;
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
            id: calendarWidgetLoader
            anchors.fill: parent
            active: win.isWidgetOn("calendar")
            sourceComponent: CalendarWidget {
                shellRoot: root
                hostWin: win
            }
        }

        Loader {
            id: notesWidgetLoader
            anchors.fill: parent
            active: win.isWidgetOn("notes")
            sourceComponent: NotesWidget {
                shellRoot: root
                hostWin: win
            }
        }
        Loader {
            id: loader_analog
            anchors.fill: parent
            z: win.focusedWidgetKey === "analog" ? 12 : 2
            property bool targetOn: win.isWidgetOn("analog")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_analog.stop(); }
                else { unload_analog.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_analog; interval: 240; repeat: false; onTriggered: loader_analog.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: AnalogClockWidget { shellRoot: root; hostWin: win }
        }
        Loader {
            id: loader_storage
            anchors.fill: parent
            z: win.focusedWidgetKey === "storage" ? 12 : 2
            property bool targetOn: win.isWidgetOn("storage")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_storage.stop(); }
                else { unload_storage.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_storage; interval: 240; repeat: false; onTriggered: loader_storage.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: StorageWidget { shellRoot: root; hostWin: win }
        }
        Loader {
            id: loader_network
            anchors.fill: parent
            z: win.focusedWidgetKey === "network" ? 12 : 2
            property bool targetOn: win.isWidgetOn("network")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_network.stop(); }
                else { unload_network.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_network; interval: 240; repeat: false; onTriggered: loader_network.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: NetworkWidget { shellRoot: root; hostWin: win }
        }
        Loader {
            id: loader_pomodoro
            anchors.fill: parent
            z: win.focusedWidgetKey === "pomodoro" ? 12 : 2
            property bool targetOn: win.isWidgetOn("pomodoro")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_pomodoro.stop(); }
                else { unload_pomodoro.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_pomodoro; interval: 240; repeat: false; onTriggered: loader_pomodoro.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: PomodoroWidget { shellRoot: root; hostWin: win }
        }
        Loader {
            id: loader_quote
            anchors.fill: parent
            z: win.focusedWidgetKey === "quote" ? 12 : 2
            property bool targetOn: win.isWidgetOn("quote")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_quote.stop(); }
                else { unload_quote.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_quote; interval: 240; repeat: false; onTriggered: loader_quote.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: QuoteWidget { shellRoot: root; hostWin: win }
        }
        Loader {
            id: loader_worldclock
            anchors.fill: parent
            z: win.focusedWidgetKey === "worldclock" ? 12 : 2
            property bool targetOn: win.isWidgetOn("worldclock")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_worldclock.stop(); }
                else { unload_worldclock.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_worldclock; interval: 240; repeat: false; onTriggered: loader_worldclock.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: WorldClockWidget { shellRoot: root; hostWin: win }
        }
        Loader {
            id: loader_reminders
            anchors.fill: parent
            z: win.focusedWidgetKey === "reminders" ? 12 : 2
            property bool targetOn: win.isWidgetOn("reminders")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_reminders.stop(); }
                else { unload_reminders.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_reminders; interval: 240; repeat: false; onTriggered: loader_reminders.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: RemindersWidget { shellRoot: root; hostWin: win }
        }
        Loader {
            id: loader_photo
            anchors.fill: parent
            z: win.focusedWidgetKey === "photo" ? 12 : 2
            property bool targetOn: win.isWidgetOn("photo")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_photo.stop(); }
                else { unload_photo.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_photo; interval: 240; repeat: false; onTriggered: loader_photo.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: PhotoWidget { shellRoot: root; hostWin: win }
        }
        Loader {
            id: loader_shortcuts
            anchors.fill: parent
            z: win.focusedWidgetKey === "shortcuts" ? 12 : 2
            property bool targetOn: win.isWidgetOn("shortcuts")
            property bool keepAlive: false
            onTargetOnChanged: {
                if (targetOn) { keepAlive = true; unload_shortcuts.stop(); }
                else { unload_shortcuts.restart(); }
            }
            Component.onCompleted: keepAlive = targetOn
            Timer { id: unload_shortcuts; interval: 240; repeat: false; onTriggered: loader_shortcuts.keepAlive = false }
            active: targetOn || keepAlive
            sourceComponent: ShortcutsWidget { shellRoot: root; hostWin: win }
        }
    }

    // 6. MACOS FLOATING DOCK (AUTO-HIDE + EVENT-STREAM + REGION MASK)
    // ========================================================================
    Dock { shellRoot: root }

    MacLockScreen { shellRoot: root }







    // ========================================================================
    // PANEL STUDIO KHUSUS: EDIT WIDGET DOCK
    // ========================================================================
    
}
