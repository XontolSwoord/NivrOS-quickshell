#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/quickshell"
START_SHELL=1
[ "${1:-}" = "--no-start" ] && START_SHELL=0

echo "=== NivrOS 1.0 Quickshell Installer ==="

install_deps() {
    if command -v pacman >/dev/null 2>&1; then
        echo "[1/4] Arch-based system detected (pacman)"
        sudo pacman -S --needed --noconfirm niri wf-recorder ffmpeg grim slurp wl-clipboard \
            playerctl brightnessctl libnotify networkmanager bluez bluez-utils python \
            pipewire pipewire-pulse wireplumber power-profiles-daemon jq alacritty qt6ct
        if ! command -v qs >/dev/null 2>&1; then
            if command -v paru >/dev/null 2>&1; then
                paru -S --needed --noconfirm quickshell-git
            elif command -v yay >/dev/null 2>&1; then
                yay -S --needed --noconfirm quickshell-git
            else
                echo "WARNING: 'qs' not found. Install quickshell (AUR: quickshell-git)."
            fi
        fi
    elif command -v dnf >/dev/null 2>&1; then
        echo "[1/4] Fedora detected (dnf)"
        sudo dnf install -y niri wf-recorder ffmpeg-free grim slurp wl-clipboard playerctl \
            brightnessctl libnotify NetworkManager bluez python3 pulseaudio-utils wireplumber \
            power-profiles-daemon jq alacritty qt6ct
        command -v qs >/dev/null 2>&1 || echo "WARNING: 'qs' not found. Install 'quickshell' (Fedora repos or COPR)."
    elif command -v apt-get >/dev/null 2>&1; then
        echo "[1/4] Debian/Ubuntu detected (apt)"
        sudo apt-get update
        sudo apt-get install -y wf-recorder ffmpeg grim slurp wl-clipboard playerctl brightnessctl \
            libnotify-bin network-manager bluez python3 pulseaudio-utils wireplumber \
            power-profiles-daemon jq alacritty qt6ct
        command -v niri >/dev/null 2>&1 || echo "WARNING: 'niri' not found. Install it from the Niri docs."
        command -v qs >/dev/null 2>&1 || echo "WARNING: 'qs' not found. Build quickshell from the official docs."
    else
        echo "WARNING: Unknown package manager. Install dependencies manually (see README)."
    fi
}

deploy_config() {
    echo "[2/4] Deploying shell to $TARGET_DIR"
    if [ "$REPO_DIR" != "$TARGET_DIR" ]; then
        if [ -d "$TARGET_DIR" ]; then
            BACKUP_DIR="${TARGET_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
            echo "      Backing up existing config to $BACKUP_DIR"
            mv "$TARGET_DIR" "$BACKUP_DIR"
        fi
        mkdir -p "$TARGET_DIR"
        tar --exclude=.git --exclude=docs -C "$REPO_DIR" -cf - . | tar -C "$TARGET_DIR" -xf -
    fi

    chmod +x "$TARGET_DIR"/scripts/*.sh "$TARGET_DIR"/scripts/*.py 2>/dev/null || true

    if [ ! -f "$TARGET_DIR/profile.json" ]; then
        USER_TITLE="$(printf '%s' "${USER:-User}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
        printf '{"name":"%s","avatar":"","language":"id","surfaceMode":"liquid","liquidVariant":"mac","colorScheme":"dark","islandLayoutMode":"floating","islandEnabled":true,"islandMusicHover":true,"islandBehaviorMode":"adaptive","notifDurationSec":4,"recAudioMode":"system","recResolution":"native"}\n' "$USER_TITLE" > "$TARGET_DIR/profile.json"
    fi
    [ -f "$TARGET_DIR/icon_map.json" ] || echo '{}' > "$TARGET_DIR/icon_map.json"

    mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos"
}

copy_example() {
    local src="$1" dst="$2"
    [ -f "$src" ] || return 0
    if [ -e "$dst" ]; then
        echo "      Skipped (already exists): $dst"
        echo "      Merge manually from: $src"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "      Installed: $dst"
    fi
}

deploy_extras() {
    echo "[3/4] Installing example configs (never overwrites existing files)"
    copy_example "$TARGET_DIR/config/niri/config.kdl.example" "$HOME/.config/niri/config.kdl"
    copy_example "$TARGET_DIR/config/alacritty/alacritty.toml.example" "$HOME/.config/alacritty/alacritty.toml"
}

start_shell() {
    echo "[4/4] Starting Quickshell"
    if [ "$START_SHELL" -eq 1 ] && [ -n "${WAYLAND_DISPLAY:-}" ] && command -v qs >/dev/null 2>&1; then
        pkill -x qs 2>/dev/null || true
        sleep 0.3
        nohup qs >/tmp/qs_nivros.log 2>&1 &
        echo "DONE: NivrOS is running. Log: /tmp/qs_nivros.log"
    else
        echo "Skipped (no Wayland session, 'qs' missing, or --no-start). Log in to Niri to start it."
    fi
    echo "Add to ~/.config/niri/config.kdl:  spawn-at-startup \"qs\""
}

install_deps
deploy_config
deploy_extras
start_shell
