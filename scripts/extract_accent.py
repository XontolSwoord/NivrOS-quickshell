import sys, urllib.parse
try:
    from PIL import Image
    raw = sys.argv[1] if len(sys.argv) > 1 else ""
    if raw.startswith("file://"):
        raw = urllib.parse.unquote(raw[7:])
    im = Image.open(raw).convert("RGB").resize((48, 48))
    best = (10, 132, 255)
    best_s = -1.0
    for r, g, b in im.getdata():
        mx, mn = max(r, g, b), min(r, g, b)
        sat = (mx - mn) / max(1, mx)
        lum = (r + g + b) / 3.0
        if 38 < lum < 232 and sat > 0.14:
            sc = sat * 120.0 + (128.0 - abs(lum - 132.0)) * 0.25
            if sc > best_s:
                best_s = sc
                best = (r, g, b)
    if best_s < 0:
        for r, g, b in im.getdata():
            mx, mn = max(r, g, b), min(r, g, b)
            sat = (mx - mn) / max(1, mx)
            lum = (r + g + b) / 3.0
            if 28 < lum < 240:
                sc = sat * 100.0
                if sc > best_s:
                    best_s = sc
                    best = (r, g, b)
    print("#%02X%02X%02X" % best)
except Exception:
    print("#0A84FF")
