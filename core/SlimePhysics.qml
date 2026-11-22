import QtQuick

Item {
    id: slimeRoot
    property bool slimeActive: true
    property real target: 0.0
    property real viscosity: 0.25
    property real stiffness: 185.0
    property real damping: 16.0
    property real maxStretchY: 0.14

    property real value: target
    property real velocity: 0.0
    property bool settled: true

    readonly property real stretchY: {
        if (!slimeActive) return 1.0;
        return 1.0 + Math.max(-0.05, Math.min(maxStretchY, velocity * 0.044));
    }
    readonly property real stretchX: {
        if (!slimeActive) return 1.0;
        return 1.0 / Math.sqrt(Math.max(0.88, stretchY));
    }

    onSlimeActiveChanged: {
        if (!slimeActive) {
            slimeTicker.stop();
            value = target;
            velocity = 0.0;
            settled = true;
        }
    }

    onTargetChanged: {
        if (!slimeActive) {
            value = target;
            velocity = 0.0;
            settled = true;
            return;
        }
        if (Math.abs(target - value) > 0.0005 || Math.abs(velocity) > 0.0005) {
            settled = false;
            slimeTicker.start();
        }
    }

    Timer {
        id: slimeTicker
        interval: 16
        repeat: true
        running: false
        onTriggered: {
            if (!slimeRoot.slimeActive) {
                slimeRoot.value = slimeRoot.target;
                slimeRoot.velocity = 0.0;
                slimeRoot.settled = true;
                stop();
                return;
            }
            let dt = 0.016;
            let force = (slimeRoot.target - slimeRoot.value) * slimeRoot.stiffness;
            let dampForce = -slimeRoot.velocity * slimeRoot.damping;
            let accel = (force + dampForce) / (1.0 + slimeRoot.viscosity);
            slimeRoot.velocity += accel * dt;
            slimeRoot.value += slimeRoot.velocity * dt;

            if (Math.abs(slimeRoot.target - slimeRoot.value) < 0.0008 && Math.abs(slimeRoot.velocity) < 0.0008) {
                slimeRoot.value = slimeRoot.target;
                slimeRoot.velocity = 0.0;
                slimeRoot.settled = true;
                stop();
            }
        }
    }
}
