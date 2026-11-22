pragma Singleton
import QtQuick

QtObject {
    id: engine

    function drawGlobalAeroGlass(ctx, w, h, rad, offX, offY, scrW, scrH, isCircular, drawRim) {
        if (w <= 1 || h <= 1) return;
        ctx.reset();
        ctx.save();

        if (rad > 0) {
            ctx.beginPath();
            ctx.roundedRect(0.5, 0.5, w - 1, h - 1, rad, rad);
            ctx.clip();
        }

        let dark = ShellState.isDark;

        // ── MODE 1: SOLID MURNI ───────────────────────────────────────
        if (ShellState.isSolid) {
            ctx.fillStyle = dark ? "#18181A" : "#FFFFFF";
            ctx.fillRect(0, 0, w, h);

            if (rad > 0) {
                ctx.strokeStyle = dark ? "rgba(255, 255, 255, 0.11)" : "rgba(0, 0, 0, 0.10)";
                ctx.lineWidth = 1.0;
                ctx.beginPath();
                ctx.roundedRect(0.5, 0.5, w - 1.0, h - 1.0, rad, rad);
                ctx.stroke();
            } else if (drawRim) {
                ctx.fillStyle = dark ? "rgba(255, 255, 255, 0.10)" : "rgba(0, 0, 0, 0.08)";
                ctx.fillRect(0, h - 1, w, 1);
            }
            ctx.restore();
            return;
        }

        let variant = ShellState.liquidVariant;

        if (variant === "aero") {
            // ═══ OPSI 2: WINDOWS 7 AERO GLASS (Top Gloss + Garis Diagonal + Bingkai Kristal) ═══
            let op = ShellState.aeroBaseOpacity;
            let bright = ShellState.aeroSheenBright;
            let thick = ShellState.aeroSheenWidth;

            let baseAlpha = Math.min(0.84, 0.10 + op * 0.52);
            ctx.fillStyle = dark
                ? ("rgba(12, 18, 30, " + baseAlpha.toFixed(3) + ")")
                : ("rgba(242, 248, 255, " + Math.min(0.88, 0.36 + op * 0.44).toFixed(3) + ")");
            ctx.fillRect(0, 0, w, h);

            // Pantulan kaca atas khas Windows 7 Aero
            let topGloss = ctx.createLinearGradient(0, 0, 0, h * 0.52);
            topGloss.addColorStop(0.0, "rgba(255, 255, 255, " + ((dark ? 0.14 : 0.42) * (0.35 + bright * 0.65)).toFixed(3) + ")");
            topGloss.addColorStop(1.0, "rgba(255, 255, 255, 0.0)");
            ctx.fillStyle = topGloss;
            ctx.fillRect(0, 0, w, h * 0.52);

            // Garis kilau diagonal Aero
            if (bright > 0.005) {
                if (isCircular) {
                    let radSpread = 0.28 + thick * 0.36;
                    let domeGrad = ctx.createRadialGradient(w * 0.34, h * 0.24, 2, w * 0.48, h * 0.48, w * radSpread);
                    domeGrad.addColorStop(0.0, "rgba(255, 255, 255, " + ((dark ? 0.22 : 0.38) * bright).toFixed(3) + ")");
                    domeGrad.addColorStop(0.55, "rgba(200, 235, 255, " + ((dark ? 0.08 : 0.16) * bright).toFixed(3) + ")");
                    domeGrad.addColorStop(1.0, "rgba(255, 255, 255, 0.0)");
                    ctx.fillStyle = domeGrad;
                    ctx.fillRect(0, 0, w, h);
                } else {
                    let peak1 = (dark ? 0.19 : 0.36) * bright;
                    let peak2 = (dark ? 0.10 : 0.20) * bright;
                    let c1 = 0.32;
                    let c2 = 0.66;
                    let hw1 = 0.05 + thick * 0.22;
                    let hw2 = 0.035 + thick * 0.14;

                    let blinGrad = ctx.createLinearGradient(0, 0, w * 0.78, h * 0.78);
                    blinGrad.addColorStop(0.0, "rgba(255, 255, 255, 0.0)");
                    blinGrad.addColorStop(Math.max(0.01, c1 - hw1), "rgba(255, 255, 255, 0.0)");
                    blinGrad.addColorStop(Math.max(0.02, c1 - hw1 * 0.45), "rgba(255, 255, 255, " + (peak1 * 0.55).toFixed(3) + ")");
                    blinGrad.addColorStop(c1, "rgba(255, 255, 255, " + peak1.toFixed(3) + ")");
                    blinGrad.addColorStop(Math.min(0.98, c1 + hw1 * 0.45), "rgba(255, 255, 255, " + (peak1 * 0.55).toFixed(3) + ")");
                    blinGrad.addColorStop(Math.min(0.99, c1 + hw1), "rgba(255, 255, 255, 0.0)");

                    if (thick > 0.20 && (c1 + hw1) < (c2 - hw2 * 0.3)) {
                        let s2Start = Math.max(c1 + hw1, c2 - hw2);
                        blinGrad.addColorStop(Math.min(0.97, s2Start), "rgba(255, 255, 255, 0.0)");
                        blinGrad.addColorStop(c2, "rgba(255, 255, 255, " + peak2.toFixed(3) + ")");
                        blinGrad.addColorStop(Math.min(0.99, c2 + hw2), "rgba(255, 255, 255, 0.0)");
                    }

                    blinGrad.addColorStop(1.0, "rgba(255, 255, 255, 0.0)");
                    ctx.fillStyle = blinGrad;
                    ctx.fillRect(0, 0, w, h);
                }
            }

            if (rad > 0) {
                // Bingkai luar kristal + garis dalam gelap tipis khas Windows 7 Aero
                ctx.strokeStyle = dark
                    ? ("rgba(215, 238, 255, " + (0.20 + bright * 0.26).toFixed(3) + ")")
                    : "rgba(255, 255, 255, 0.68)";
                ctx.lineWidth = 1.0;
                ctx.beginPath();
                ctx.roundedRect(0.5, 0.5, w - 1.0, h - 1.0, rad, rad);
                ctx.stroke();

                ctx.strokeStyle = dark ? "rgba(0, 0, 0, 0.32)" : "rgba(25, 45, 75, 0.16)";
                ctx.lineWidth = 0.8;
                ctx.beginPath();
                ctx.roundedRect(1.5, 1.5, w - 3.0, h - 3.0, Math.max(1.0, rad - 1.0), Math.max(1.0, rad - 1.0));
                ctx.stroke();
            }

        } else if (variant === "liquid") {
            // ═══ OPSI 3: APPLE LIQUID GLASS (Timbul Halus + Lengkungan Cahaya Tepi) ═══
            let op = ShellState.liquidOpacity;
            let refr = ShellState.liquidRefraction;
            let fringe = ShellState.liquidFringing;

            // Dasar kaca optik bersih
            ctx.fillStyle = dark
                ? ("rgba(22, 28, 42, " + Math.min(0.28, 0.03 + op * 0.18).toFixed(3) + ")")
                : ("rgba(250, 252, 255, " + Math.min(0.74, 0.28 + op * 0.38).toFixed(3) + ")");
            ctx.fillRect(0, 0, w, h);

            // Lengkungan cahaya cembung halus (top meniscus catchlight + bottom bounce + subtle depth)
            let dropGrad = ctx.createLinearGradient(0, 0, 0, h);
            dropGrad.addColorStop(0.0, "rgba(255, 255, 255, " + ((dark ? 0.18 : 0.46) + refr * 0.18).toFixed(3) + ")");
            dropGrad.addColorStop(0.08, "rgba(255, 255, 255, " + ((dark ? 0.05 : 0.14) + refr * 0.05).toFixed(3) + ")");
            dropGrad.addColorStop(0.50, "rgba(255, 255, 255, 0.0)");
            dropGrad.addColorStop(0.90, dark ? "rgba(0, 0, 0, 0.08)" : "rgba(20, 30, 50, 0.03)");
            dropGrad.addColorStop(1.0, "rgba(235, 248, 255, " + ((dark ? 0.13 : 0.30) + refr * 0.14).toFixed(3) + ")");
            ctx.fillStyle = dropGrad;
            ctx.fillRect(0, 0, w, h);

            if (rad > 0) {
                // Inner bevel highlight (memberi kesan kaca sedikit timbul di tepi dalam)
                let innerBevel = ctx.createLinearGradient(0, 0, 0, h);
                innerBevel.addColorStop(0.0, "rgba(255, 255, 255, " + ((dark ? 0.22 : 0.55) + refr * 0.15).toFixed(3) + ")");
                innerBevel.addColorStop(0.28, "rgba(255, 255, 255, 0.03)");
                innerBevel.addColorStop(0.75, dark ? "rgba(0, 0, 0, 0.14)" : "rgba(0, 0, 0, 0.04)");
                innerBevel.addColorStop(1.0, "rgba(255, 255, 255, " + ((dark ? 0.14 : 0.35) + refr * 0.10).toFixed(3) + ")");
                ctx.strokeStyle = innerBevel;
                ctx.lineWidth = 1.25;
                ctx.beginPath();
                ctx.roundedRect(1.6, 1.6, w - 3.2, h - 3.2, Math.max(1.0, rad - 1.1), Math.max(1.0, rad - 1.1));
                ctx.stroke();

                // Dispersi kromatik tipis di pinggiran lengkungan
                if (fringe > 0.01) {
                    ctx.strokeStyle = "rgba(110, 215, 255, " + (0.26 * fringe).toFixed(3) + ")";
                    ctx.lineWidth = 1.1;
                    ctx.beginPath();
                    ctx.roundedRect(0.9, 0.9, w - 1.8, h - 1.8, rad, rad);
                    ctx.stroke();

                    ctx.strokeStyle = "rgba(255, 145, 215, " + (0.20 * fringe).toFixed(3) + ")";
                    ctx.lineWidth = 0.9;
                    ctx.beginPath();
                    ctx.roundedRect(1.5, 1.5, w - 3.0, h - 3.0, Math.max(1.0, rad - 0.6), Math.max(1.0, rad - 0.6));
                    ctx.stroke();
                }

                // Specular rim luar 45 derajat
                let rimGrad = ctx.createLinearGradient(0, 0, w, h);
                rimGrad.addColorStop(0.0, dark ? ("rgba(255, 255, 255, " + (0.44 + refr * 0.24).toFixed(3) + ")") : "rgba(255, 255, 255, 0.85)");
                rimGrad.addColorStop(0.45, dark ? "rgba(255, 255, 255, 0.13)" : "rgba(0, 0, 0, 0.08)");
                rimGrad.addColorStop(1.0, dark ? ("rgba(240, 250, 255, " + (0.32 + refr * 0.20).toFixed(3) + ")") : "rgba(255, 255, 255, 0.65)");
                ctx.strokeStyle = rimGrad;
                ctx.lineWidth = 1.15;
                ctx.beginPath();
                ctx.roundedRect(0.5, 0.5, w - 1.0, h - 1.0, rad, rad);
                ctx.stroke();
            }

        } else {
            // ═══ OPSI 1: CLEAN GLASS ("mac" — Soft Clear Frosted Blur Bersih & Nyaman) ═══
            let op = ShellState.macOpacity;
            let frost = ShellState.macFrost;

            ctx.fillStyle = dark
                ? ("rgba(15, 17, 25, " + Math.min(0.86, 0.14 + op * 0.54).toFixed(3) + ")")
                : ("rgba(249, 250, 253, " + Math.min(0.92, 0.46 + op * 0.42).toFixed(3) + ")");
            ctx.fillRect(0, 0, w, h);

            if (frost > 0.005) {
                ctx.fillStyle = dark
                    ? ("rgba(230, 236, 248, " + (0.02 + frost * 0.08).toFixed(3) + ")")
                    : ("rgba(255, 255, 255, " + (0.18 + frost * 0.22).toFixed(3) + ")");
                ctx.fillRect(0, 0, w, h);
            }

            if (rad > 0) {
                ctx.strokeStyle = dark
                    ? ("rgba(255, 255, 255, " + (0.13 + frost * 0.13).toFixed(3) + ")")
                    : ("rgba(0, 0, 0, " + (0.09 + frost * 0.07).toFixed(3) + ")");
                ctx.lineWidth = 1.0;
                ctx.beginPath();
                ctx.roundedRect(0.5, 0.5, w - 1.0, h - 1.0, rad, rad);
                ctx.stroke();
            }
        }

        ctx.restore();
    }

    function drawMergedNotch(ctx, totalW, h, botRad, filletR) {
        if (totalW <= 2 || h <= 2) return;
        ctx.reset();
        ctx.save();

        let f = Math.max(0, filletR);
        let bodyW = Math.max(12, totalW - f * 2);
        let rB = Math.min(botRad, bodyW * 0.5, Math.max(4, h - f));

        ctx.beginPath();
        ctx.moveTo(0, -1);
        ctx.lineTo(totalW, -1);
        ctx.lineTo(totalW, 0);
        if (f > 0) {
            ctx.arc(totalW, f, f, -Math.PI * 0.5, Math.PI, true);
        }
        ctx.lineTo(f + bodyW, h - rB);
        ctx.arc(f + bodyW - rB, h - rB, rB, 0, Math.PI * 0.5, false);
        ctx.lineTo(f + rB, h);
        ctx.arc(f + rB, h - rB, rB, Math.PI * 0.5, Math.PI, false);
        if (f > 0) {
            ctx.lineTo(f, f);
            ctx.arc(0, f, f, 0, -Math.PI * 0.5, true);
        }
        ctx.lineTo(0, -1);
        ctx.closePath();

        ctx.fillStyle = "#000000";
        ctx.fill();

        ctx.strokeStyle = "rgba(255, 255, 255, 0.14)";
        ctx.lineWidth = 1.0;
        ctx.beginPath();
        if (f > 0) {
            ctx.arc(totalW, f, f - 0.5, -Math.PI * 0.5, Math.PI, true);
        } else {
            ctx.moveTo(totalW - 0.5, 0);
        }
        ctx.lineTo(f + bodyW - 0.5, h - rB);
        ctx.arc(f + bodyW - rB, h - rB, Math.max(1, rB - 0.5), 0, Math.PI * 0.5, false);
        ctx.lineTo(f + rB, h - 0.5);
        ctx.arc(f + rB, h - rB, Math.max(1, rB - 0.5), Math.PI * 0.5, Math.PI, false);
        if (f > 0) {
            ctx.lineTo(f + 0.5, f);
            ctx.arc(0, f, f - 0.5, 0, -Math.PI * 0.5, true);
        }
        ctx.stroke();

        ctx.restore();
    }
}
