pragma Singleton
import QtQuick

QtObject {
    id: tokens

    readonly property bool isDark: ShellState.isDark
    readonly property bool isSolid: ShellState.isSolid
    readonly property string variant: ShellState.liquidVariant

    // ── Latar Permukaan Utama (iNiR Solid Tonal Hierarchy & Liquid Clean) ──
    readonly property color windowBg: isSolid
        ? (isDark ? "#18191D" : "#F5F6F8")
        : (isDark ? "#BC12141E" : "#E4F5F7FB")

    readonly property color sidebarBg: isSolid
        ? (isDark ? "#1F2026" : "#ECEEF2")
        : (isDark ? "#64141724" : "#B8E8ECF4")

    readonly property color cardBg: isSolid
        ? (isDark ? "#25272E" : "#FFFFFF")
        : (isDark ? "#28FFFFFF" : "#D6FFFFFF")

    readonly property color cardHoverBg: isSolid
        ? (isDark ? "#31343D" : "#E6E9EF")
        : (isDark ? "#38FFFFFF" : "#ECFFFFFF")

    readonly property color inputBg: isSolid
        ? (isDark ? "#2C2E36" : "#EAECEF")
        : (isDark ? "#2CFFFFFF" : "#BCFFFFFF")

    readonly property color barBg: isSolid
        ? (isDark ? "#18191D" : "#F5F6F8")
        : (isDark ? "#96141418" : "#A8F6F7FA")

    readonly property color dockBg: isSolid
        ? (isDark ? "#1E2026" : "#F2F3F6")
        : (isDark ? "#88141620" : "#A2F5F7FB")

    // ── Border & Divider Bersih ─────────────────────────────────────────
    readonly property color borderSubtle: isSolid
        ? (isDark ? "#32353F" : "#D8DCE3")
        : (isDark ? "#36FFFFFF" : "#2E000000")

    readonly property color borderStrong: isSolid
        ? (isDark ? "#434754" : "#C5CAD3")
        : (isDark ? "#52FFFFFF" : "#42000000")

    readonly property color dividerColor: isSolid
        ? (isDark ? "#2E313A" : "#E0E3E9")
        : (isDark ? "#24FFFFFF" : "#1C000000")

    // ── Tipografi & Tint Ikon Dinamis (Tajam di Light maupun Dark Mode) ──
    readonly property color textPrimary: isDark ? "#F5F5F7" : "#18191C"
    readonly property color textSecondary: isDark ? "#B0B3BC" : "#4E525B"
    readonly property color textMuted: isDark ? "#8A8E99" : "#6C707A"
    readonly property color textOnAccent: "#FFFFFF"
    readonly property color iconTint: isDark ? "#F5F5F7" : "#18191C"
    readonly property color iconMutedTint: isDark ? "#B0B3BC" : "#4E525B"


    // ── Aksen Sistem ────────────────────────────────────────────────────
    readonly property color accent: ShellState.adaptiveAccent ? ShellState.extractedAccent : (isDark ? "#0A84FF" : "#007AFF")
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, isDark ? 0.24 : 0.16)
    readonly property color success: isDark ? "#30D158" : "#28CD41"
    readonly property color warning: isDark ? "#FFD60A" : "#FF9F0A"
    readonly property color danger: isDark ? "#FF453A" : "#FF3B30"
}
