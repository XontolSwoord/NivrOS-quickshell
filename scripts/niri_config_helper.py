import os
import re
import subprocess
import sys
import tempfile

CFG = os.path.expanduser("~/.config/niri/config.kdl")

def reload_niri():
    bin_path = "/usr/local/bin/niri-glass" if os.path.exists("/usr/local/bin/niri-glass") else "niri"
    subprocess.run([bin_path, "msg", "action", "load-config-file"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def find_block_span(text, keyword):
    m = re.search(rf'(?m)^\s*{keyword}\s*\{{', text)
    if not m:
        return None
    start = m.start()
    brace_start = text.find("{", m.start())
    depth = 0
    for i in range(brace_start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return (start, i + 1)
    return None

def read_state():
    st = {
        "tp_tap": "1", "tp_nat": "1", "tp_dwt": "1", "tp_left": "0",
        "tp_accel": "0.20", "tp_prof": "adaptive", "tp_scroll": "1.00",
        "ms_accel": "0.00", "ms_prof": "flat", "ms_nat": "0",
        "ms_left": "0", "ms_mid": "0", "ms_scroll": "1.00",
        "kb_delay": "300", "kb_rate": "35", "ffm": "0", "warp": "0"
    }
    if os.path.isfile(CFG):
        txt = open(CFG, encoding="utf-8", errors="ignore").read()
        span = find_block_span(txt, "input")
        blk = txt[span[0]:span[1]] if span else txt
        tp_m = re.search(r'touchpad\s*\{([\s\S]*?)\}', blk)
        if tp_m:
            tp = tp_m.group(1)
            st["tp_tap"] = "1" if re.search(r'^\s*tap\b', tp, re.M) else "0"
            st["tp_nat"] = "1" if re.search(r'^\s*natural-scroll\b', tp, re.M) else "0"
            st["tp_dwt"] = "1" if re.search(r'^\s*dwt\b', tp, re.M) else "0"
            st["tp_left"] = "1" if re.search(r'^\s*left-handed\b', tp, re.M) else "0"
            a = re.search(r'accel-speed\s+([-\d.]+)', tp)
            if a: st["tp_accel"] = a.group(1)
            p = re.search(r'accel-profile\s+"([^"]+)"', tp)
            if p: st["tp_prof"] = p.group(1)
            s = re.search(r'scroll-factor\s+([-\d.]+)', tp)
            if s: st["tp_scroll"] = s.group(1)
        ms_m = re.search(r'mouse\s*\{([\s\S]*?)\}', blk)
        if ms_m:
            ms = ms_m.group(1)
            st["ms_nat"] = "1" if re.search(r'^\s*natural-scroll\b', ms, re.M) else "0"
            st["ms_left"] = "1" if re.search(r'^\s*left-handed\b', ms, re.M) else "0"
            st["ms_mid"] = "1" if re.search(r'^\s*middle-emulation\b', ms, re.M) else "0"
            a = re.search(r'accel-speed\s+([-\d.]+)', ms)
            if a: st["ms_accel"] = a.group(1)
            p = re.search(r'accel-profile\s+"([^"]+)"', ms)
            if p: st["ms_prof"] = p.group(1)
            s = re.search(r'scroll-factor\s+([-\d.]+)', ms)
            if s: st["ms_scroll"] = s.group(1)
        kb_m = re.search(r'keyboard\s*\{([\s\S]*?)\}', blk)
        if kb_m:
            kb = kb_m.group(1)
            d = re.search(r'repeat-delay\s+(\d+)', kb)
            if d: st["kb_delay"] = d.group(1)
            r = re.search(r'repeat-rate\s+(\d+)', kb)
            if r: st["kb_rate"] = r.group(1)
        st["ffm"] = "1" if "focus-follows-mouse" in blk else "0"
        st["warp"] = "1" if "warp-mouse-to-focus" in blk else "0"
    order = ["tp_tap","tp_nat","tp_dwt","tp_left","tp_accel","tp_prof","tp_scroll","ms_accel","ms_prof","ms_nat","ms_left","ms_mid","ms_scroll","kb_delay","kb_rate","ffm","warp"]
    print("|".join(st[k] for k in order))

def read_binds():
    if not os.path.isfile(CFG):
        return
    txt = open(CFG, encoding="utf-8", errors="ignore").read()
    rows = []
    for m in re.finditer(r'^\s*([A-Za-z0-9_+]+)\s*\{([^\n\}]+)\}', txt, re.M):
        if "+" in m.group(1):
            combo = m.group(1).strip()
            act = " ".join(m.group(2).strip().split())
            rows.append(f"{combo}|{act}")
    print("\n".join(rows[:32]))

def set_full(tp_tap, tp_nat, tp_dwt, tp_left, tp_accel, tp_prof, tp_scroll, ms_accel, ms_prof, ms_nat, ms_left, ms_mid, ms_scroll, kb_delay, kb_rate, ffm, warp):
    if not os.path.isfile(CFG):
        return
    txt = open(CFG, encoding="utf-8").read()
    # Hapus blok duplikat NIVROS INPUT lama jika ada
    txt = re.sub(r'\n?// --- NIVROS INPUT START ---[\s\S]*?// --- NIVROS INPUT END ---\n?', '', txt)

    # Pertahankan blok xkb / trackpoint / tablet dari blok input awal jika ada
    xkb_part = ""
    old_span = find_block_span(txt, "input")
    if old_span:
        old_inp = txt[old_span[0]:old_span[1]]
        kb_span = find_block_span(old_inp, "keyboard")
        if kb_span:
            xkb_m = find_block_span(old_inp[kb_span[0]:kb_span[1]], "xkb")
            if xkb_m:
                xkb_part = "        " + old_inp[kb_span[0]:kb_span[1]][xkb_m[0]:xkb_m[1]].strip() + "\n"

    tp_lines = []
    if tp_tap == "1": tp_lines.append("        tap")
    if tp_nat == "1": tp_lines.append("        natural-scroll")
    if tp_dwt == "1": tp_lines.append("        dwt")
    if tp_left == "1": tp_lines.append("        left-handed")
    tp_lines.append(f"        accel-speed {float(tp_accel):.2f}")
    tp_lines.append(f'        accel-profile "{tp_prof}"')
    tp_lines.append(f"        scroll-factor {float(tp_scroll):.2f}")

    ms_lines = []
    if ms_nat == "1": ms_lines.append("        natural-scroll")
    if ms_left == "1": ms_lines.append("        left-handed")
    if ms_mid == "1": ms_lines.append("        middle-emulation")
    ms_lines.append(f"        accel-speed {float(ms_accel):.2f}")
    ms_lines.append(f'        accel-profile "{ms_prof}"')
    ms_lines.append(f"        scroll-factor {float(ms_scroll):.2f}")

    extra_lines = ""
    if ffm == "1":
        extra_lines += '    focus-follows-mouse max-scroll-amount="0%"\n'
    if warp == "1":
        extra_lines += "    warp-mouse-to-focus\n"

    new_input = (
        "input {\n"
        "    keyboard {\n"
        f"{xkb_part}"
        f"        repeat-delay {int(float(kb_delay))}\n"
        f"        repeat-rate {int(float(kb_rate))}\n"
        "    }\n"
        "    touchpad {\n"
        + "\n".join(tp_lines) + "\n"
        "    }\n"
        "    mouse {\n"
        + "\n".join(ms_lines) + "\n"
        "    }\n"
        f"{extra_lines}"
        "}"
    )

    if old_span:
        cand = txt[:old_span[0]] + new_input + txt[old_span[1]:]
    else:
        cand = new_input + "\n\n" + txt

    bin_path = "/usr/local/bin/niri-glass" if os.path.exists("/usr/local/bin/niri-glass") else "niri"
    with tempfile.NamedTemporaryFile("w", suffix=".kdl", delete=False, encoding="utf-8") as tf:
        tf.write(cand)
        tmp_check = tf.name
    try:
        res = subprocess.run([bin_path, "validate", "-c", tmp_check], capture_output=True, text=True)
        if res.returncode == 0:
            open(CFG, "w", encoding="utf-8").write(cand)
            reload_niri()
        else:
            print("NIRI INPUT VALIDATE ERR:", res.stderr.strip(), file=sys.stderr)
    finally:
        if os.path.exists(tmp_check):
            os.remove(tmp_check)

def add_bind(combo, cmd):
    combo = combo.strip()
    cmd = cmd.strip().replace('"', '\\"')
    if not combo or not cmd or not os.path.isfile(CFG):
        return
    txt = open(CFG, encoding="utf-8").read()
    line = f'    {combo} {{ spawn-sh "{cmd}"; }}\n'
    if "binds {" in txt:
        txt = txt.replace("binds {", "binds {\n" + line, 1)
    else:
        txt += f"\nbinds {{\n{line}}}\n"
    open(CFG, "w", encoding="utf-8").write(txt)
    reload_niri()

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "read_state":
        read_state()
    elif mode == "read_binds":
        read_binds()
    elif mode == "set_full" and len(sys.argv) >= 19:
        set_full(*sys.argv[2:19])
    elif mode == "add_bind" and len(sys.argv) >= 4:
        add_bind(sys.argv[2], sys.argv[3])
