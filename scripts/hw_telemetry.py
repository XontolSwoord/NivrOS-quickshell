import glob
import os
import shutil

health = 100
cycles = 0
tech = "Li-ion"

bats = sorted(glob.glob("/sys/class/power_supply/BAT*"))
for b in bats[:1]:
    try:
        ef = float(open(os.path.join(b, "energy_full")).read().strip())
        efd = float(open(os.path.join(b, "energy_full_design")).read().strip())
        if efd > 0:
            health = min(100, max(40, int(round(ef / efd * 100))))
    except Exception:
        try:
            cf = float(open(os.path.join(b, "charge_full")).read().strip())
            cfd = float(open(os.path.join(b, "charge_full_design")).read().strip())
            if cfd > 0:
                health = min(100, max(40, int(round(cf / cfd * 100))))
        except Exception:
            pass
    try:
        cycles = int(open(os.path.join(b, "cycle_count")).read().strip())
    except Exception:
        pass
    try:
        t = open(os.path.join(b, "technology")).read().strip()
        if t:
            tech = t
    except Exception:
        pass

up = 7200
if os.path.exists("/proc/uptime"):
    try:
        up = int(float(open("/proc/uptime").read().split()[0]))
    except Exception:
        pass

du = shutil.disk_usage("/")
tot = round(du.total / (1024 ** 3), 1)
used = round(du.used / (1024 ** 3), 1)
sysg = round(min(used * 0.42, 48.0), 1)
appg = round(min(used * 0.28, 42.0), 1)
medg = round(max(1.0, used - sysg - appg), 1)

uptime_str = f"{up // 3600}j {(up % 3600) // 60}m sesi aktif"
print(f"{health}|{cycles}|{tech}|{uptime_str}|{tot}|{used}|{sysg}|{appg}|{medg}")
