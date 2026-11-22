pragma Singleton
import QtQuick

QtObject {
    id: motion

    // ── Konstanta Fisika Pegas Dunia Nyata ──────────────────────────────
    // 1. Floating Mode: pegas responsif & presisi tanpa overshoot berlebihan
    readonly property real floatMass: 1.0
    readonly property real floatSpring: 6.2
    readonly property real floatDamping: 0.56
    readonly property real floatEpsilon: 0.001

    // 2. Merged Mode: pegas lebih kenyal dengan deformasi jelly halus
    readonly property real jellyMass: 1.15
    readonly property real jellyStiffness: 240.0
    readonly property real jellyDamping: 17.5
    readonly property real jellyIntensity: 0.085
    readonly property real settleEpsilon: 0.0008

    // Konservasi luas (squash & stretch) berbasis kecepatan gerak normalisasi
    function computeJellyStretch(velocityNorm, intensity) {
        let clamped = Math.max(-1.4, Math.min(1.4, velocityNorm));
        let stretch = 1.0 + Math.abs(clamped) * (intensity || jellyIntensity);
        let squash = 1.0 / Math.sqrt(stretch);
        return {
            x: Number(squash.toFixed(4)),
            y: Number(stretch.toFixed(4))
        };
    }
}
