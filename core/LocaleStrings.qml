pragma Singleton
import QtQuick

QtObject {
    id: loc

    readonly property bool isId: ShellState.language === "id"

    function t(idText, enText) {
        return isId ? idText : enText;
    }

    // Menu Bar & Dropdown
    readonly property string menuWindow: t("Jendela", "Window")
    readonly property string menuDesktop: t("Desktop", "Desktop")
    readonly property string actToggleOverview: t("Tampilkan Ringkasan Jendela", "Toggle Overview")
    readonly property string actToggleFullscreen: t("Mode Layar Penuh", "Toggle Fullscreen")
    readonly property string actCenterColumn: t("Tengahkan Kolom Aktif", "Center Focused Column")
    readonly property string actCloseWindow: t("Tutup Jendela Aktif", "Close Focused Window")
    readonly property string actNextWallpaper: t("Ganti Wallpaper Berikutnya", "Next Wallpaper")
    readonly property string actScreenshot: t("Ambil Tangkapan Layar...", "Take Screenshot...")
    readonly property string actEditWidgets: t("Atur Tata Letak Widget", "Customize Desktop Widgets")
    readonly property string actResetWidgets: t("Pulihkan Tata Letak Widget", "Reset Widget Layout")

    // System Settings & Appearance
    readonly property string settingsTitle: t("Pengaturan Sistem", "System Settings")
    readonly property string searchPlaceholder: t("Cari pengaturan...", "Search settings...")
    readonly property string navAppearance: t("Tampilan", "Appearance")
    readonly property string navWallpaper: t("Wallpaper", "Wallpaper")
    readonly property string navDisplaySound: t("Layar & Suara", "Displays & Sound")
    readonly property string navWifi: "Wi-Fi"
    readonly property string navBluetooth: "Bluetooth"
    readonly property string navBatterySystem: t("Baterai & Sistem", "Battery & System")
    readonly property string navLanguageProfile: t("Bahasa & Profil", "Language & Profile")

    readonly property string secMaterial: t("Material Permukaan", "Surface Material")
    readonly property string optSolid: "Solid"
    readonly property string optSolidDesc: t("Permukaan solid bersih hemat daya", "Clean solid surface for battery efficiency")
    readonly property string optLiquid: "Liquid"
    readonly property string optLiquidDesc: t("Efek kaca berlapis & refraksi", "Layered glass & refraction effect")

    readonly property string secColorTheme: t("Tema Warna Sistem", "System Color Theme")
    readonly property string secColorThemeDesc: t("Diterapkan ke seluruh bar, dock, widget, dan popup", "Applied across bar, dock, widgets, and popups")
    readonly property string optLight: t("Terang", "Light")
    readonly property string optDark: t("Gelap", "Dark")

    readonly property string secIslandLayout: t("Tampilan Dynamic Island", "Dynamic Island Style")
    readonly property string secIslandLayoutDesc: t("Atur posisi Island menyatu dengan tepi atas layar atau melayang", "Choose whether Island merges with top screen edge or floats")
    readonly property string optIslandFloating: t("Melayang", "Floating")
    readonly property string optIslandFloatingDesc: t("Kapsul melayang terpisah di tengah atas", "Floating capsule detached at top center")
    readonly property string optIslandMerged: t("Menyatu", "Merged")
    readonly property string optIslandMergedDesc: t("Notch hitam murni menyatu ke tepi atas layar", "Pure black notch merged into top screen edge")

    readonly property string secDockBehavior: t("Perilaku Dock", "Dock Behavior")
    readonly property string optDockSmart: t("Cerdas", "Smart")
    readonly property string optDockAutoHide: t("Sembunyi Otomatis", "Auto-Hide")
    readonly property string optDockAlways: t("Selalu Tampil", "Always Visible")

    readonly property string secLanguage: t("Bahasa Antarmuka", "Interface Language")
    readonly property string secProfile: t("Profil Pengguna", "User Profile")
}
