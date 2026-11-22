import fcntl
import os
import re
import sys

LOCK_PATH = "/tmp/nivros_glass_sync.lock"

with open(LOCK_PATH, "w") as lock_file:
    fcntl.flock(lock_file, fcntl.LOCK_EX)

    variant = sys.argv[1] if len(sys.argv) > 1 else "liquid"
    opacity_pct = float(sys.argv[2]) if len(sys.argv) > 2 else 68.0
    is_solid = (sys.argv[3] == "1") if len(sys.argv) > 3 else False
    is_dark = (sys.argv[4] == "1") if len(sys.argv) > 4 else True

    if is_solid:
        target_opacity = 1.00
    else:
        base_map = {
            "clean": 0.86,
            "aero": 0.72,
            "liquid": max(0.32, min(0.95, opacity_pct / 100.0))
        }
        target_opacity = base_map.get(variant, 0.68)

    alacritty_cfg = os.path.expanduser("~/.config/alacritty/alacritty.toml")
    os.makedirs(os.path.dirname(alacritty_cfg), exist_ok=True)

    txt = open(alacritty_cfg, encoding="utf-8").read() if os.path.isfile(alacritty_cfg) else ""
    # Bersihkan blok sync lama jika ada
    txt = re.sub(r'\n?# --- NIVROS TERMINAL SYNC START ---[\s\S]*?# --- NIVROS TERMINAL SYNC END ---\n?', '', txt)

    # Update opacity di [window] jika sudah ada, atau tambahkan di blok sync
    if re.search(r'^\s*opacity\s*=', txt, re.M):
        txt = re.sub(r'^\s*opacity\s*=\s*[0-9.]+', f'opacity = {target_opacity:.2f}', txt, flags=re.M)
        win_block = ""
    elif "[window]" in txt:
        txt = txt.replace("[window]", f"[window]\nopacity = {target_opacity:.2f}", 1)
        win_block = ""
    else:
        win_block = f"[window]\nopacity = {target_opacity:.2f}\n"

    # Sesuaikan warna dasar terminal agar teks tetap tajam pada mode Light maupun Dark
    if is_dark:
        bg_hex = "#0E1017"
        fg_hex = "#F2F4F8"
    else:
        bg_hex = "#F5F7FB"
        fg_hex = "#14161F"

    color_block = ""
    if "[colors.primary]" not in txt:
        color_block = f'[colors.primary]\nbackground = "{bg_hex}"\nforeground = "{fg_hex}"\n'
    else:
        txt = re.sub(r'(background\s*=\s*)"#[0-9A-Fa-f]{6}"', rf'\1"{bg_hex}"', txt)
        txt = re.sub(r'(foreground\s*=\s*)"#[0-9A-Fa-f]{6}"', rf'\1"{fg_hex}"', txt)

    sync_section = (
        "\n# --- NIVROS TERMINAL SYNC START ---\n"
        + win_block
        + color_block
        + "# --- NIVROS TERMINAL SYNC END ---\n"
    )
    open(alacritty_cfg, "w", encoding="utf-8").write(txt.rstrip() + "\n" + sync_section)
