import fcntl
import os
import re
import subprocess
import sys
import tempfile

if len(sys.argv) < 7:
    sys.exit(0)

LOCK_PATH = "/tmp/kairo_niri_glass.lock"

with open(LOCK_PATH, "w") as lock_fp:
    fcntl.flock(lock_fp, fcntl.LOCK_EX)

    mode, p1, p2, p3, p4, p5 = sys.argv[1:7]
    scheme = sys.argv[7] if len(sys.argv) > 7 else "dark"
    is_dark = (scheme == "dark")

    cfg_path = os.path.expanduser("~/.config/niri/config.kdl")
    alacritty_path = os.path.expanduser("~/.config/alacritty/alacritty.toml")

    def atomic_write(target_path, content):
        d = os.path.dirname(target_path)
        os.makedirs(d, exist_ok=True)
        fd, tmp_path = tempfile.mkstemp(prefix=".kairo_tmp_", dir=d)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                f.write(content)
            os.replace(tmp_path, target_path)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def set_alacritty_opacity(val):
        if not os.path.exists(alacritty_path):
            return
        atxt = open(alacritty_path, encoding="utf-8").read()
        atxt = re.sub(r"\n?# BEGIN KAIRO LIQUID OPACITY[\s\S]*?# END KAIRO LIQUID OPACITY\n?", "", atxt)
        if val is not None:
            atxt = atxt.rstrip() + f"\n\n# BEGIN KAIRO LIQUID OPACITY\n[window]\nopacity = {val}\n# END KAIRO LIQUID OPACITY\n"
        atomic_write(alacritty_path, atxt)

    if not os.path.exists(cfg_path):
        sys.exit(0)

    orig = open(cfg_path, encoding="utf-8").read()
    base = re.sub(r"\n?// BEGIN KAIRO GLASS ENGINE[\s\S]*?// END KAIRO GLASS ENGINE\n?", "", orig)
    base = re.sub(r"\n?// BEGIN KAIRO LIQUID GLASS[\s\S]*?// END KAIRO LIQUID GLASS\n?", "", base)

    # Kelola blok blur utama niri-glass secara dinamis agar slider Frost / Transparansi berdampak nyata
    def apply_blur_block(kdl_text, passes, offset, noise, saturation):
        new_blur = f"blur {{\n    passes {passes}\n    offset {offset}\n    noise {noise:.3f}\n    saturation {saturation:.2f}\n}}"
        if re.search(r"(?m)^\s*blur\s*\{[^}]*\}", kdl_text):
            return re.sub(r"(?m)^\s*blur\s*\{[^}]*\}", new_blur, kdl_text, count=1)
        return new_blur + "\n\n" + kdl_text

    if mode == "solid":
        set_alacritty_opacity(1.0)
        block = """
// BEGIN KAIRO GLASS ENGINE
window-rule {
    match app-id=".*"
    geometry-corner-radius 12
    clip-to-geometry true
}
// END KAIRO GLASS ENGINE
"""
    elif mode == "mac":
        # Opsi 1: Clean Glass (Soft Clear Frosted Blur seperti gambar 3, tanpa kilau berlebih)
        mac_op = float(p1)     # 0.10 .. 0.88 (semakin besar = semakin pekat)
        mac_frost = float(p2)  # 0.00 .. 1.00 (semakin besar = blur semakin lembut/tebal)
        op_val = round(max(0.42, min(0.95, 0.36 + mac_op * 0.62)), 2)
        set_alacritty_opacity(op_val)

        b_passes = max(2, min(5, int(round(2 + mac_frost * 3))))
        b_offset = max(2, min(6, int(round(2 + mac_frost * 4))))
        base = apply_blur_block(base, b_passes, b_offset, 0.015, 1.06)

        rim_col = "#ffffff28" if is_dark else "#0000001e"
        block = f"""
// BEGIN KAIRO GLASS ENGINE
window-rule {{
    match app-id=".*"
    geometry-corner-radius 14
    clip-to-geometry true
    border {{
        on
        width 1
        active-color "{rim_col}"
        inactive-color "{rim_col}"
    }}
    background-effect {{
        blur true
        xray false
    }}
}}
// END KAIRO GLASS ENGINE
"""
    elif mode == "aero":
        # Opsi 2: Aero Glass Windows 7 (Kaca jernih kristal + warna hidup + bingkai mengilap seperti gambar 4)
        aero_op = float(p1)
        aero_bright = float(p2)
        aero_width = float(p3)
        op_val = round(max(0.28, min(0.84, 0.24 + aero_op * 0.62)), 2)
        set_alacritty_opacity(op_val)

        b_passes = 2 if aero_width < 0.5 else 3
        base = apply_blur_block(base, b_passes, 3, 0.0, 1.24)

        rim_alpha = format(int(min(255, max(65, round((0.36 + aero_bright * 0.50) * 255)))), "02x")
        block = f"""
// BEGIN KAIRO GLASS ENGINE
window-rule {{
    match app-id=".*"
    geometry-corner-radius 12
    clip-to-geometry true
    border {{
        on
        width 1
        active-color "#ffffff{rim_alpha}"
        inactive-color "#ffffff36"
    }}
    background-effect {{
        blur true
        xray true
    }}
}}
// END KAIRO GLASS ENGINE
"""
    else:
        # Opsi 3: Apple Liquid Glass (Blur ringan + pembengkokan latar & cahaya tipis lembut di pinggir)
        refr = round(max(0.95, min(2.25, 0.65 + float(p1) * 0.42)), 2)
        fringe = round(min(0.42, float(p2) * 0.42), 2)
        edge_l = round(max(0.22, min(0.45, 0.16 + float(p3) * 0.24)), 2)
        liq_op = float(p5)

        op_val = round(max(0.14, min(0.66, 0.12 + liq_op * 0.52)), 2)
        set_alacritty_opacity(op_val)

        # Blur ringan agar gambar latar tetap terbaca & lengkungannya terlihat jelas
        block = f"""
// BEGIN KAIRO GLASS ENGINE
window-rule {{
    match app-id=".*"
    geometry-corner-radius 24
    clip-to-geometry true
    draw-border-with-background false
    focus-ring {{
        off
    }}
    border {{
        off
    }}
    shadow {{
        on
        softness 30
        spread 3
        offset x=0 y=8
        color "#00000070"
    }}
    background-effect {{
        blur false
        xray true
        liquid-glass {{
            refraction-strength {refr}
            power-factor 5.5
            refraction-a 0.02
            refraction-b 3.5
            refraction-c 3.5
            refraction-d 6.0
            refraction-power 0.62
            edge-thickness 0.048
            edge-padding 0.0
            glow-weight 0.035
            glow-bias 0.0
            glow-edge0 0.30
            glow-edge1 0.96
            edge-lighting {edge_l}
            fringing {fringe}
            physical-refraction 0.0
            lens-distortion 0.0
            brightness 1.05
            contrast 1.03
            saturation 1.12
            vibrancy 0.32
            adaptive-dim 0.0
            adaptive-boost 0.12
            refraction-dilute 0.0
        }}
    }}
}}
// END KAIRO GLASS ENGINE
"""

    cand = base.rstrip() + "\n" + block
    bin_path = "/usr/local/bin/niri-glass" if os.path.exists("/usr/local/bin/niri-glass") else "niri"

    with tempfile.NamedTemporaryFile("w", suffix=".kdl", delete=False, encoding="utf-8") as tf:
        tf.write(cand)
        tmp_check = tf.name

    try:
        res = subprocess.run([bin_path, "validate", "-c", tmp_check], capture_output=True, text=True)
        if res.returncode == 0:
            atomic_write(cfg_path, cand)
            subprocess.run([bin_path, "msg", "action", "load-config-file"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            print("VALIDATE FAILED:", res.stderr.strip(), file=sys.stderr)
    finally:
        if os.path.exists(tmp_check):
            os.remove(tmp_check)
