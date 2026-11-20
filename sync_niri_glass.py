import os, re, sys, subprocess, tempfile

if len(sys.argv) < 7:
    sys.exit(0)

mode, p1, p2, p3, p4, p5 = sys.argv[1:7]
cfg_path = os.path.expanduser("~/.config/niri/config.kdl")
alacritty_path = os.path.expanduser("~/.config/alacritty/alacritty.toml")

def atomic_write(target_path, content):
    d = os.path.dirname(target_path)
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

has_top_blur = bool(re.search(r"(?m)^\s*blur\s*\{", base))

if mode == "mac":
    op_val = round(max(0.68, min(0.96, 0.72 + float(p1) * 0.24)), 2)
    set_alacritty_opacity(op_val)
    block = """
// BEGIN KAIRO GLASS ENGINE
window-rule {
    match app-id=".*"
    geometry-corner-radius 14
    clip-to-geometry true
}
// END KAIRO GLASS ENGINE
"""
elif mode == "aero":
    op_val = round(max(0.35, min(0.78, 0.38 + float(p1) * 0.36)), 2)
    set_alacritty_opacity(op_val)
    blur_hdr = "" if has_top_blur else "blur {\n    on\n    noise 0\n    saturation 1.05\n    passes 2\n}\n"
    block = f"""
// BEGIN KAIRO GLASS ENGINE
{blur_hdr}window-rule {{
    match app-id=".*"
    geometry-corner-radius 14
    clip-to-geometry true
    border {{
        on
        width 1
        active-color "#ffffff66"
        inactive-color "#ffffff28"
    }}
    background-effect {{
        blur true
        xray true
    }}
}}
// END KAIRO GLASS ENGINE
"""
else:
    # OPSI 3: 100% PARAMETER DEFAULT & SCREENSHOT ZAROUTT/NIRI-GLASS
    # p1=refr(0.8..4.2), p2=fringe(0.0..1.0), p3=edge_lighting(0.4..1.2), p4=lens_dist(0.0..0.5), p5=opacity(0.0..1.0)
    refr = round(float(p1), 2)
    fringe = round(float(p2), 2)
    edge_l = round(float(p3), 2)
    lens_d = round(float(p4), 2)
    # Default slider Transparansi tinggi -> Alacritty opacity 0.00 (bening air 100% seperti SS GitHub)
    op_val = round(max(0.0, min(0.35, max(0.0, float(p5) - 0.22) * 0.55)), 2)
    set_alacritty_opacity(op_val)
    block = f"""
// BEGIN KAIRO GLASS ENGINE
window-rule {{
    match app-id=".*"
    geometry-corner-radius 20
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
        softness 28
        spread 3
        offset x=0 y=8
        color "#00000066"
    }}
    background-effect {{
        blur false
        xray true
        liquid-glass {{
            refraction-strength {refr}
            power-factor 3.0
            refraction-a 0.04
            refraction-b 5.0
            refraction-c 5.0
            refraction-d 8.0
            refraction-power 0.65
            edge-thickness 0.16
            edge-padding 0.0
            glow-weight 0.08
            glow-bias 0.0
            glow-edge0 0.3
            glow-edge1 0.9
            edge-lighting {edge_l}
            fringing {fringe}
            physical-refraction 0.0
            lens-distortion {lens_d}
            brightness 1.0
            contrast 1.0
            saturation 0.95
            vibrancy 0.15
            adaptive-dim 0.0
            adaptive-boost 0.0
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
    else:
        print("VALIDATE FAILED:", res.stderr.strip(), file=sys.stderr)
finally:
    if os.path.exists(tmp_check):
        os.remove(tmp_check)
