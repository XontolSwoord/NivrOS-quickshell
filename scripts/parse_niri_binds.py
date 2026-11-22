import json
import os
import re

cfg = os.path.expanduser("~/.config/niri/config.kdl")
out = []
if os.path.isfile(cfg):
    txt = open(cfg, encoding="utf-8").read()
    for line in txt.splitlines():
        s = line.strip()
        if not s or s.startswith("//"):
            continue
        m = re.match(r'^((?:Mod|Super|Alt|Ctrl|Shift|XF86|Print)[A-Za-z0-9_+\-]*)\b([^{]*)\{\s*([^;}]+)', s)
        if not m:
            continue
        keys = m.group(1).replace("Mod", "Super")
        meta = m.group(2)
        act = m.group(3).strip()
        tm = re.search(r'hotkey-overlay-title="([^"]+)"', meta)
        desc = tm.group(1) if tm else act
        cat = "Sistem"
        if "workspace" in act:
            cat = "Workspace"
        elif any(k in act for k in ["window", "column", "focus", "move", "consume", "expel", "fullscreen", "floating"]):
            cat = "Jendela"
        elif "spawn" in act or "Audio" in keys or "Brightness" in keys:
            cat = "Aplikasi & Media"
        out.append({"keys": keys, "desc": desc, "cat": cat})

print(json.dumps(out))
