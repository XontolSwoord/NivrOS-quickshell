pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: state

    // ── Branding & Versi Sistem Dinamis ─────────────────────────────────
    readonly property string osName: "NivrOS"
    readonly property string osVersion: "1.0"
    readonly property string osFullName: osName + " " + osVersion
    readonly property string osTagline: "FLUID TILING • GLASS EXPERIENCE"
    readonly property string developerName: "XontolSwoord"
    readonly property string developerGithub: "github.com/XontolSwoord"
    readonly property string developerUrl: "https://github.com/XontolSwoord"

    // ── State Machine Utama UI & Tema Seluruh Sistem ────────────────────
    property string surfaceMode: "liquid"        // "solid" | "liquid"
    property string liquidVariant: "liquid"         // "mac" | "aero" | "liquid"
    property string colorScheme: "dark"          // "dark" | "light"
    property string islandLayoutMode: "floating" // "floating" | "merged" (KHUSUS Island)
    property bool islandEnabled: true
    property bool islandMusicHover: true
    property string islandBehaviorMode: "adaptive" // "compact" | "adaptive" | "expanded"
    property int notifDurationSec: 4
    property int testNotifSeq: 0
    property string testNotifApp: ""
    property string testNotifSummary: ""
    property string testNotifBody: ""
    function triggerTestNotification(app, summary, body) {
        testNotifApp = app || "NivrOS";
        testNotifSummary = summary || "Notifikasi Uji";
        testNotifBody = body || "";
        testNotifSeq = testNotifSeq + 1;
    }
    property string language: "id"               // "id" | "en"
    property bool adaptiveAccent: false
    property color extractedAccent: "#0A84FF"
    property bool nightLightEnabled: false
    property int nightLightTemp: 4200
    property bool isRecording: false
    property int recordingSeconds: 0
    property string recAudioMode: "system"     // "none" | "system" | "sys_mic"
    property string recResolution: "native"    // "native" | "360" | "720" | "1080" | "1440" | "2160"
    property string osdKind: ""                  // "volume" | "brightness" | ""
    property int osdValue: 0
    property bool osdMuted: false
    property int osdSeq: 0
    property var niriWorkspaces: [{ idx: 1, active: true, windows: 0 }]

    function triggerOsd(kind, val, muted) {
        osdKind = kind;
        osdValue = Math.max(0, Math.min(100, Math.round(val)));
        osdMuted = !!muted;
        osdSeq = osdSeq + 1;
    }

    readonly property bool isSolid: surfaceMode === "solid"
    readonly property bool isLiquid: surfaceMode === "liquid"
    readonly property bool isDark: colorScheme === "dark"
    readonly property bool isLight: colorScheme === "light"
    readonly property bool isMergedIsland: islandLayoutMode === "merged"

    property var iconMap: ({})
    function resolveIcon(iconName) {
        let k = String(iconName || "").trim();
        if (k === "") return "";
        if (k.startsWith("file://") || k.startsWith("image://")) return k;
        if (k.startsWith("/")) return "file://" + k;
        let base = k.replace(/\.(png|svg|xpm)$/i, "");
        if (iconMap && iconMap[base]) return iconMap[base];
        let low = base.toLowerCase();
        if (iconMap && iconMap[low]) return iconMap[low];
        return Quickshell.iconPath(k, true);
    }

    // ── Profil Pengguna Dinamis (Nama & Custom Avatar) ──────────────────
    property string systemUser: (Quickshell.env("USER") || "User")
    property string profileName: systemUser.charAt(0).toUpperCase() + systemUser.slice(1)
    property string profileAvatar: ""
    readonly property string profileInitials: {
        let parts = (profileName || "U").trim().split(/\s+/);
        if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
        return (parts[0] || "U").slice(0, 2).toUpperCase();
    }

    // ── State Shell & Hardware ──────────────────────────────────────────
    property bool editMode: false
    property bool dndEnabled: false
    property string activePopup: ""
    property string dockHideMode: "smart"

    property int batteryPercent: -1
    property string batteryStatus: ""
    property int bootStage: 6
    property string focusedAppName: "Finder"
    property bool musicPreviewVisible: false
    property bool wifiConnected: false

    // ── Parameter Independen 3 Sub-Opsi Liquid ──────────────────────────
    property real macOpacity: 0.41
    property real macFrost: 0.09
    property real aeroBaseOpacity: 0.42
    property real aeroSheenBright: 0.12
    property real aeroSheenWidth: 0.58
    property real liquidOpacity: 0.18
    property real liquidRefraction: 0.79
    property real liquidFringing: 0.41

    readonly property real aeroOpacity: isSolid ? 1.0 : (liquidVariant === "aero" ? aeroBaseOpacity : (liquidVariant === "liquid" ? liquidOpacity : macOpacity))
    readonly property real aeroReflection: isSolid ? 0.0 : (liquidVariant === "aero" ? aeroSheenBright : (liquidVariant === "liquid" ? liquidRefraction : macFrost))
    readonly property real activeGlassDetail: isSolid ? 0.0 : (liquidVariant === "liquid" ? liquidFringing : aeroSheenWidth)

    property var switchPopupHandler: null
    property var runCmdHandler: null
    property var saveLayoutHandler: null

    function resetGlassPresets() {
        macOpacity = 0.41;
        macFrost = 0.09;
        aeroBaseOpacity = 0.42;
        aeroSheenBright = 0.12;
        aeroSheenWidth = 0.58;
        liquidOpacity = 0.18;
        liquidRefraction = 0.79;
        liquidFringing = 0.41;
    }

    function setSurfaceMode(mode) {
        if (mode !== "solid" && mode !== "liquid") return;
        surfaceMode = mode;
        if (mode === "liquid" && liquidVariant !== "mac" && liquidVariant !== "aero" && liquidVariant !== "liquid") {
            liquidVariant = "mac";
        }
    }

    function setLiquidVariant(variant) {
        if (variant !== "mac" && variant !== "aero" && variant !== "liquid") return;
        surfaceMode = "liquid";
        liquidVariant = variant;
    }

    function setColorScheme(scheme) {
        if (scheme !== "dark" && scheme !== "light") return;
        colorScheme = scheme;
    }

    function toggleColorScheme() {
        colorScheme = (colorScheme === "dark") ? "light" : "dark";
    }

    function setIslandLayoutMode(mode) {
        if (mode !== "floating" && mode !== "merged") return;
        islandLayoutMode = mode;
    }

    function setLanguage(lang) {
        if (lang !== "id" && lang !== "en") return;
        language = lang;
    }

    onSurfaceModeChanged: saveProfile()
    onLiquidVariantChanged: saveProfile()
    onColorSchemeChanged: saveProfile()
    onIslandLayoutModeChanged: saveProfile()
    onIslandEnabledChanged: saveProfile()
    onIslandMusicHoverChanged: saveProfile()
    onIslandBehaviorModeChanged: saveProfile()
    onNotifDurationSecChanged: saveProfile()
    onRecAudioModeChanged: saveProfile()
    onRecResolutionChanged: saveProfile()
    onLanguageChanged: saveProfile()

    function saveProfile(newName, newAvatar) {
        if (newName !== undefined && newName !== null) {
            let trimmed = String(newName).trim();
            if (trimmed.length > 0) profileName = trimmed;
        }
        if (newAvatar !== undefined && newAvatar !== null) {
            profileAvatar = String(newAvatar).trim();
        }
        let payload = JSON.stringify({
            name: profileName,
            avatar: profileAvatar,
            language: language,
            surfaceMode: surfaceMode,
            liquidVariant: liquidVariant,
            colorScheme: colorScheme,
            islandLayoutMode: islandLayoutMode,
            islandEnabled: islandEnabled,
            islandMusicHover: islandMusicHover,
            islandBehaviorMode: islandBehaviorMode,
            notifDurationSec: notifDurationSec,
            recAudioMode: recAudioMode,
            recResolution: recResolution
        });
        let b64 = Qt.btoa(unescape(encodeURIComponent(payload)));
        runCmd("mkdir -p ~/.config/quickshell && printf '%s' '" + b64 + "' | base64 -d > ~/.config/quickshell/profile.json");
    }

    function switchPopup(name) {
        if (typeof switchPopupHandler === "function") switchPopupHandler(name);
    }

    function runCmd(cmd) {
        if (typeof runCmdHandler === "function") runCmdHandler(cmd);
    }

    function saveLayout() {
        if (typeof saveLayoutHandler === "function") saveLayoutHandler();
    }

    function formatTime(sec) {
        let s = Math.max(0, Math.floor(sec || 0));
        let m = Math.floor(s / 60);
        let r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }
}
