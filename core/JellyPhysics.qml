import QtQuick

Item {
    id: solver
    visible: false
    width: 0
    height: 0

    // Target & nilai keluaran fisika pegas teredam
    property real target: 0.0
    property real value: 0.0
    property real velocity: 0.0

    // Parameter pegas fisik (bisa dikustomisasi per komponen)
    property real mass: MotionEngine.jellyMass
    property real stiffness: MotionEngine.jellyStiffness
    property real damping: MotionEngine.jellyDamping
    property real jellyAmount: MotionEngine.jellyIntensity
    property real velocityScale: 0.0022
    property bool snapImmediately: false

    // Keluaran deformasi elastis jelly (otomatis kembali ke 1.0 saat diam)
    readonly property real stretchX: {
        let j = MotionEngine.computeJellyStretch(velocity * velocityScale, jellyAmount);
        return j.x;
    }
    readonly property real stretchY: {
        let j = MotionEngine.computeJellyStretch(velocity * velocityScale, jellyAmount);
        return j.y;
    }

    readonly property bool settled: Math.abs(target - value) < MotionEngine.settleEpsilon
                                    && Math.abs(velocity) < MotionEngine.settleEpsilon

    onTargetChanged: {
        if (snapImmediately) {
            value = target;
            velocity = 0.0;
        } else if (!simFrame.running && !settled) {
            simFrame.running = true;
        }
    }

    Component.onCompleted: {
        value = target;
        velocity = 0.0;
    }

    FrameAnimation {
        id: simFrame
        running: false
        onTriggered: {
            let dt = Math.min(frameTime, 0.033);
            if (dt <= 0) return;

            let disp = solver.value - solver.target;
            let force = (-solver.stiffness * disp) - (solver.damping * solver.velocity);
            let accel = force / Math.max(0.1, solver.mass);

            solver.velocity += accel * dt;
            solver.value += solver.velocity * dt;

            if (Math.abs(solver.target - solver.value) < MotionEngine.settleEpsilon
                && Math.abs(solver.velocity) < MotionEngine.settleEpsilon) {
                solver.value = solver.target;
                solver.velocity = 0.0;
                running = false;
            }
        }
    }
}
