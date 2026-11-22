#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/quickshell"

echo "=== NivrOS 1.0 Quickshell Installer ==="

install_deps() {
    if command -v pacman >/dev/null 2>&1; then
        echo "[1/3] Mendeteksi Arch-based Linux (pacman)..."
        PKGS=(wf-recorder ffmpeg grim slurp wl-clipboard playerctl brightnessctl libnotify networkmanager bluez bluez-utils python pipewire pipewire-pulse pavucontrol jq)
        sudo pacman -S --needed --noconfirm "${PKGS[@]}"

        if ! command -v qs >/dev/null 2>&1; then
            if command -v paru >/dev/null 2>&1; then
                paru -S --needed --noconfirm quickshell-git
            elif command -v yay >/dev/null 2>&1; then
                yay -S --needed --noconfirm quickshell-git
            else
                echo "PERINGATAN: 'quickshell' belum terpasang. Pasang 'quickshell-git' lewat AUR (yay/paru)."
            fi
        fi
    elif command -v dnf >/dev/null 2>&1; then
        echo "[1/3] Mendeteksi Fedora (dnf)..."
        sudo dnf install -y wf-recorder ffmpeg grim slurp wl-clipboard playerctl brightnessctl libnotify NetworkManager bluez python3 pipewire-utils pavucontrol jq
        command -v qs >/dev/null 2>&1 || echo "PERINGATAN: Pasang paket 'quickshell' dari COPR/repositori Fedora Anda."
    elif command -v apt-get >/dev/null 2>&1; then
        echo "[1/3] Mendeteksi Debian/Ubuntu (apt)..."
        sudo apt-get update
        sudo apt-get install -y wf-recorder ffmpeg grim slurp wl-clipboard playerctl brightnessctl libnotify-bin network-manager bluez python3 pulseaudio-utils pavucontrol jq
        command -v qs >/dev/null 2>&1 || echo "PERINGATAN: Bangun atau pasang 'quickshell' sesuai dokumentasi resmi Quickshell."
    else
        echo "PERINGATAN: Package manager tidak dikenali. Pastikan dependensi terpasang manual."
    fi
}

deploy_config() {
    echo "[2/3] Menyalin konfigurasi ke $TARGET_DIR..."
    if [ "$REPO_DIR" != "$TARGET_DIR" ]; then
        if [ -d "$TARGET_DIR" ]; then
            BACKUP_DIR="${TARGET_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
            echo "      Mem-backup konfigurasi lama ke $BACKUP_DIR"
            mv "$TARGET_DIR" "$BACKUP_DIR"
        fi
        mkdir -p "$(dirname "$TARGET_DIR")"
        cp -r "$REPO_DIR" "$TARGET_DIR"
    fi

    chmod +x "$TARGET_DIR"/scripts/*.sh "$TARGET_DIR"/scripts/*.py 2>/dev/null || true

    # Buat file state default jika belum ada
    if [ ! -f "$TARGET_DIR/profile.json" ]; then
        USER_TITLE="$(printf '%s' "${USER:-User}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
        printf '{"name":"%s","avatar":"","language":"id","surfaceMode":"liquid","liquidVariant":"mac","colorScheme":"dark","islandLayoutMode":"floating","islandEnabled":true,"islandMusicHover":true,"islandBehaviorMode":"adaptive","notifDurationSec":4,"recAudioMode":"system","recResolution":"native"}\n' "$USER_TITLE" > "$TARGET_DIR/profile.json"
    fi
    [ -f "$TARGET_DIR/icon_map.json" ] || echo '{}' > "$TARGET_DIR/icon_map.json"
}

restart_shell() {
    echo "[3/3] Menjalankan Quickshell..."
    pkill -x qs 2>/dev/null || true
    sleep 0.3
    nohup qs >/tmp/qs_nivros.log 2>&1 &
    echo "SELESAI: NivrOS Quickshell aktif! Tambahkan 'spawn-at-startup \"qs\"' pada ~/.config/niri/config.kdl."
}

install_deps
deploy_config
restart_shell
