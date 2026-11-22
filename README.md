# NivrOS-quickshell

Desktop shell bergaya macOS + Liquid Glass berbasis **Quickshell** untuk **Niri** Wayland compositor.

## Highlights

- **Top Bar & Dynamic Island**: notifikasi interaktif, indikator media/OSD/recording/timer, mode adaptif/compact/expanded.
- **Control Center, Popups & Settings**: tema (Solid / Liquid Glass, Dark / Light), notifikasi, audio/jaringan, info sistem.
- **Dock & App Launcher**: launcher, dock responsif, lock screen.
- **Wallpaper Transitions**: transisi wallpaper crossfade.
- **Portable & Auto-Save**: path dinamis (`$HOME`) dan preferensi tersimpan lokal di `profile.json`.

## Project Structure

    assets/               # aset visual & logo NivrOS
    bar/                  # TopBar & Dynamic Island
    core/                 # state singleton (ShellState), tema, utilitas
    dock/                 # dock & komponen terkait
    pam/                  # konfigurasi PAM untuk lock screen
    popups/               # Control Center, Settings, Lock Screen, About
    scripts/              # skrip helper telemetri, Niri, otomatisasi
    wallpaperTransitions/ # efek transisi wallpaper
    widgets/              # widget desktop
    shell.qml             # entry point Quickshell
    WallpaperCrossfader.qml
    sync_niri_glass.py    # sinkronisasi efek glass ke config Niri
    glass_defaults.json   # default tema glass
    widgets.json          # konfigurasi widget
    install.sh            # installer dependensi & deployment

## Quick Start

    git clone https://github.com/XontolSwoord/NivrOS-quickshell.git ~/.config/quickshell
    cd ~/.config/quickshell
    chmod +x install.sh
    ./install.sh

Biar jalan otomatis saat login, tambahkan ke `~/.config/niri/config.kdl`:

    spawn-at-startup "qs"

## License

Released under the MIT License.
