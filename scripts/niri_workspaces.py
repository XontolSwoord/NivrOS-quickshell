import json
import subprocess

try:
    raw = subprocess.check_output(["niri", "msg", "-j", "workspaces"], text=True)
    ws = json.loads(raw)
    ws.sort(key=lambda x: x.get("idx", 0))
    out = [{"idx": w.get("idx", 1), "active": bool(w.get("is_active", False))} for w in ws]
    print(json.dumps(out if out else [{"idx": 1, "active": True}]))
except Exception:
    print(json.dumps([{"idx": 1, "active": True}]))
