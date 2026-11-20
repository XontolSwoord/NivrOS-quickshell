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

        if (ShellState.glassStyle === "aero") {
            let op = ShellState.aeroBaseOpacity;
            let bright = ShellState.aeroSheenBright;
            let thick = ShellState.aeroSheenWidth;

            let darkAlpha = Math.min(0.84, 0.08 + op * 0.54);
            ctx.fillStyle = "rgba(14, 16, 26, " + darkAlpha.toFixed(3) + ")";
            ctx.fillRect(0, 0, w, h);

            ctx.fillStyle = "rgba(255, 255, 255, " + (0.015 + bright * 0.035).toFixed(3) + ")";
            ctx.fillRect(0, 0, w, h);

            if (bright > 0.005) {
                if (isCircular) {
                    let radSpread = 0.28 + thick * 0.36;
                    let domeGrad = ctx.createRadialGradient(w * 0.34, h * 0.24, 2, w * 0.48, h * 0.48, w * radSpread);
                    domeGrad.addColorStop(0.0, "rgba(255, 255, 255, " + (0.20 * bright).toFixed(3) + ")");
                    domeGrad.addColorStop(0.55, "rgba(255, 255, 255, " + (0.07 * bright).toFixed(3) + ")");
                    domeGrad.addColorStop(1.0, "rgba(255, 255, 255, 0.0)");
                    ctx.fillStyle = domeGrad;
                    ctx.fillRect(0, 0, w, h);
                } else {
                    let peak1 = 0.165 * bright;
                    let peak2 = 0.085 * bright;
                    let c1 = 0.33;
                    let c2 = 0.67;
                    let hw1 = 0.05 + thick * 0.21;
                    let hw2 = 0.035 + thick * 0.13;

                    let blinGrad = ctx.createLinearGradient(0, 0, w * 0.78, h * 0.78);
                    blinGrad.addColorStop(0.0, "rgba(255, 255, 255, 0.0)");
                    blinGrad.addColorStop(Math.max(0.01, c1 - hw1), "rgba(255, 255, 255, 0.0)");
                    blinGrad.addColorStop(Math.max(0.02, c1 - hw1 * 0.45), "rgba(255, 255, 255, " + (peak1 * 0.55).toFixed(3) + ")");
                    blinGrad.addColorStop(c1, "rgba(255, 255, 255, " + peak1.toFixed(3) + ")");
                    blinGrad.addColorStop(Math.min(0.98, c1 + hw1 * 0.45), "rgba(255, 255, 255, " + (peak1 * 0.55).toFixed(3) + ")");
                    blinGrad.addColorStop(Math.min(0.99, c1 + hw1), "rgba(255, 255, 255, 0.0)");

                    if (thick > 0.22 && (c1 + hw1) < (c2 - hw2 * 0.3)) {
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
                ctx.strokeStyle = "rgba(255, 255, 255, " + (0.15 + bright * 0.24).toFixed(3) + ")";
                ctx.lineWidth = 1.0;
                ctx.beginPath();
                ctx.roundedRect(0.5, 0.5, w - 1.0, h - 1.0, rad, rad);
                ctx.stroke();
            } else if (drawRim) {
                ctx.fillStyle = "rgba(255, 255, 255, " + (0.15 + bright * 0.22).toFixed(3) + ")";
                ctx.fillRect(0, h - 1, w, 1);
            }
        } else if (ShellState.glassStyle === "liquid") {
            let op = ShellState.liquidOpacity;
            let refr = ShellState.liquidRefraction;
            let fringe = ShellState.liquidFringing;

            let clearAlpha = Math.min(0.28, 0.03 + op * 0.18);
            ctx.fillStyle = "rgba(16, 20, 30, " + clearAlpha.toFixed(3) + ")";
            ctx.fillRect(0, 0, w, h);

            let dropGrad = ctx.createLinearGradient(0, 0, 0, h);
            dropGrad.addColorStop(0.0, "rgba(255, 255, 255, " + (0.12 + refr * 0.14).toFixed(3) + ")");
            dropGrad.addColorStop(0.18, "rgba(255, 255, 255, 0.02)");
            dropGrad.addColorStop(0.82, "rgba(255, 255, 255, 0.01)");
            dropGrad.addColorStop(1.0, "rgba(235, 248, 255, " + (0.08 + refr * 0.12).toFixed(3) + ")");
            ctx.fillStyle = dropGrad;
            ctx.fillRect(0, 0, w, h);

            if (rad > 0) {
                if (fringe > 0.01) {
                    ctx.strokeStyle = "rgba(110, 215, 255, " + (0.30 * fringe).toFixed(3) + ")";
                    ctx.lineWidth = 1.25;
                    ctx.beginPath();
                    ctx.roundedRect(0.8, 0.8, w - 1.6, h - 1.6, rad, rad);
                    ctx.stroke();

                    ctx.strokeStyle = "rgba(255, 140, 215, " + (0.25 * fringe).toFixed(3) + ")";
                    ctx.lineWidth = 1.1;
                    ctx.beginPath();
                    ctx.roundedRect(1.4, 1.4, w - 2.8, h - 2.8, Math.max(1.0, rad - 0.6), Math.max(1.0, rad - 0.6));
                    ctx.stroke();
                }

                let rimGrad = ctx.createLinearGradient(0, 0, w, h);
                rimGrad.addColorStop(0.0, "rgba(255, 255, 255, " + (0.34 + refr * 0.28).toFixed(3) + ")");
                rimGrad.addColorStop(0.5, "rgba(255, 255, 255, 0.12)");
                rimGrad.addColorStop(1.0, "rgba(240, 250, 255, " + (0.28 + refr * 0.24).toFixed(3) + ")");
                ctx.strokeStyle = rimGrad;
                ctx.lineWidth = 1.2;
                ctx.beginPath();
                ctx.roundedRect(0.5, 0.5, w - 1.0, h - 1.0, rad, rad);
                ctx.stroke();
            } else if (drawRim) {
                ctx.fillStyle = "rgba(255, 255, 255, " + (0.24 + refr * 0.24).toFixed(3) + ")";
                ctx.fillRect(0, h - 1, w, 1);
            }
        } else {
            let op = ShellState.macOpacity;
            let frost = ShellState.macFrost;

            let darkAlpha = Math.min(0.84, 0.09 + op * 0.52);
            ctx.fillStyle = "rgba(14, 16, 24, " + darkAlpha.toFixed(3) + ")";
            ctx.fillRect(0, 0, w, h);

            if (frost > 0.005) {
                ctx.fillStyle = "rgba(255, 255, 255, " + (0.02 + frost * 0.10).toFixed(3) + ")";
                ctx.fillRect(0, 0, w, h);
            }

            if (rad > 0) {
                ctx.strokeStyle = "rgba(255, 255, 255, " + (0.16 + frost * 0.24).toFixed(3) + ")";
                ctx.lineWidth = 1.0;
                ctx.beginPath();
                ctx.roundedRect(0.5, 0.5, w - 1.0, h - 1.0, rad, rad);
                ctx.stroke();
            } else if (drawRim) {
                ctx.fillStyle = "rgba(255, 255, 255, " + (0.16 + frost * 0.22).toFixed(3) + ")";
                ctx.fillRect(0, h - 1, w, 1);
            }
        }

        ctx.restore();
    }
}
