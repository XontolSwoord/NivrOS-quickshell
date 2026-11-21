import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: lockScope
    required property var shellRoot

    WlSessionLock {
        id: sessionLock
        locked: lockScope.shellRoot.sessionLocked

        WlSessionLockSurface {
            id: lockSurface
            color: "#000000"

            property string pendingPassword: ""
            property bool authenticating: false
            property string errorText: ""
            property date nowDate: new Date()
            property string userName: (Quickshell.env("USER") || "arip")
            property string displayName: userName.length > 0 ? (userName.charAt(0).toUpperCase() + userName.slice(1)) : "User"
            property string avatarPath: "/var/lib/AccountsService/icons/" + userName

            function triggerShake() {
                shakeAnim.restart();
            }

            function spawnLiquidAt(px, py, strength) {
                waterShader.addDrop(px, py, strength);
            }

            function submitPassword() {
                if (authenticating) return;
                let pw = passwordInput.text;
                if (pw.length === 0) {
                    triggerShake();
                    passwordInput.forceActiveFocus();
                    return;
                }

                let pt = pillWrapper.mapToItem(waterShader, pillWrapper.width * 0.5, pillWrapper.height * 0.5);
                spawnLiquidAt(pt.x, pt.y, 1.15);

                pendingPassword = pw;
                authenticating = true;
                errorText = "";
                authWatchdog.restart();

                if (pam.active) {
                    pam.abort();
                }
                if (!pam.start()) {
                    authWatchdog.stop();
                    authenticating = false;
                    pendingPassword = "";
                    errorText = "Gagal memulai layanan PAM";
                    triggerShake();
                }
            }

            Component.onCompleted: {
                passwordInput.forceActiveFocus();
            }

            onVisibleChanged: {
                if (visible) {
                    passwordInput.forceActiveFocus();
                }
            }

            Timer {
                id: authWatchdog
                interval: 4000
                repeat: false
                onTriggered: {
                    if (lockSurface.authenticating) {
                        lockSurface.authenticating = false;
                        lockSurface.pendingPassword = "";
                        lockSurface.errorText = "Timeout autentikasi, tekan Enter lagi";
                        if (pam.active) pam.abort();
                        passwordInput.forceActiveFocus();
                    }
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: lockSurface.nowDate = new Date()
            }

            PamContext {
                id: pam
                configDirectory: "/home/arip/.config/quickshell/pam"
                config: "password"
                user: lockSurface.userName

                onResponseRequiredChanged: {
                    if (pam.responseRequired && lockSurface.pendingPassword !== "") {
                        let toSend = lockSurface.pendingPassword;
                        lockSurface.pendingPassword = "";
                        pam.respond(toSend);
                    }
                }

                onPamMessage: {
                    if (pam.messageIsError && pam.message !== "") {
                        lockSurface.errorText = pam.message;
                    }
                }

                onCompleted: (result) => {
                    authWatchdog.stop();
                    lockSurface.authenticating = false;
                    lockSurface.pendingPassword = "";

                    if (result === PamResult.Success) {
                        passwordInput.text = "";
                        lockSurface.errorText = "";
                        lockScope.shellRoot.sessionLocked = false;
                        sessionLock.unlock();
                    } else {
                        passwordInput.text = "";
                        lockSurface.errorText = (result === PamResult.MaxTries)
                            ? "Terlalu banyak percobaan"
                            : "Password salah, coba lagi";
                        lockSurface.triggerShake();
                        passwordInput.forceActiveFocus();
                    }
                }

                onError: (err) => {
                    authWatchdog.stop();
                    lockSurface.authenticating = false;
                    lockSurface.pendingPassword = "";
                    lockSurface.errorText = "Error PAM: " + PamError.toString(err);
                    lockSurface.triggerShake();
                    passwordInput.forceActiveFocus();
                }
            }

            // Root Item QQuickItem di dalam WlSessionLockSurface
            Item {
                id: lockContentRoot
                anchors.fill: parent
                focus: true

                Keys.onReturnPressed: lockSurface.submitPassword()
                Keys.onEnterPressed: lockSurface.submitPassword()

                // 1. Latar Wallpaper Ter-blur sebagai Tekstur Sumber Air
                Item {
                    id: wallpaperBaseLayer
                    anchors.fill: parent
                    visible: false

                    Image {
                        id: lockWallpaper
                        anchors.fill: parent
                        source: lockScope.shellRoot.currentWallpaper !== ""
                            ? lockScope.shellRoot.currentWallpaper
                            : lockScope.shellRoot.defaultWallpaper
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: lockWallpaper
                        source: lockWallpaper
                        blurEnabled: true
                        blur: 0.62
                        blurMax: 44
                        autoPaddingEnabled: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#111318"
                        visible: lockWallpaper.status !== Image.Ready
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#4D000000" }
                            GradientStop { position: 0.45; color: "#20000000" }
                            GradientStop { position: 1.0; color: "#66000000" }
                        }
                    }
                }

                ShaderEffectSource {
                    id: waterTextureSource
                    anchors.fill: parent
                    sourceItem: wallpaperBaseLayer
                    live: true
                    visible: false
                }

                // 2. Permukaan Air Cair TouchWiz (Refraksi GLSL Multi-Tetesan)
                ShaderEffect {
                    id: waterShader
                    anchors.fill: parent
                    property var source: waterTextureSource
                    property real time: 0.0
                    property real aspect: width / Math.max(1.0, height)

                    property vector4d drop0: Qt.vector4d(0.5, 0.5, -100.0, 0.0)
                    property vector4d drop1: Qt.vector4d(0.5, 0.5, -100.0, 0.0)
                    property vector4d drop2: Qt.vector4d(0.5, 0.5, -100.0, 0.0)
                    property vector4d drop3: Qt.vector4d(0.5, 0.5, -100.0, 0.0)
                    property vector4d drop4: Qt.vector4d(0.5, 0.5, -100.0, 0.0)
                    property vector4d drop5: Qt.vector4d(0.5, 0.5, -100.0, 0.0)
                    property vector4d drop6: Qt.vector4d(0.5, 0.5, -100.0, 0.0)
                    property vector4d drop7: Qt.vector4d(0.5, 0.5, -100.0, 0.0)

                    property int nextDropSlot: 0
                    property real lastDropTime: -100.0

                    fragmentShader: Qt.resolvedUrl("../wallpaperTransitions/touchwizRipple.frag.qsb")

                    function addDrop(px, py, strength) {
                        if (width <= 0 || height <= 0) return;
                        let u = Math.max(0.0, Math.min(1.0, px / width));
                        let v = Math.max(0.0, Math.min(1.0, py / height));
                        let vec = Qt.vector4d(u, v, time, strength);

                        switch (nextDropSlot) {
                        case 0: drop0 = vec; break;
                        case 1: drop1 = vec; break;
                        case 2: drop2 = vec; break;
                        case 3: drop3 = vec; break;
                        case 4: drop4 = vec; break;
                        case 5: drop5 = vec; break;
                        case 6: drop6 = vec; break;
                        case 7: drop7 = vec; break;
                        }
                        nextDropSlot = (nextDropSlot + 1) % 8;
                        lastDropTime = time;
                        if (!waterSimTimer.running) waterSimTimer.start();
                    }

                    Timer {
                        id: waterSimTimer
                        interval: 16
                        repeat: true
                        running: false
                        onTriggered: {
                            waterShader.time += 0.016;
                            if (waterShader.time - waterShader.lastDropTime > 1.95) {
                                stop();
                            }
                        }
                    }
                }

                // Klik di luar hanya memfokuskan input password (tidak memicu riak mengikuti kursor)
                MouseArea {
                    anchors.fill: parent
                    onPressed: passwordInput.forceActiveFocus()
                }

                // Status Bar Minimalis Pojok Kanan Atas
                Row {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 18
                    anchors.rightMargin: 26
                    spacing: 12

                    Text {
                        text: "US"
                        color: "#E6FFFFFF"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: lockScope.shellRoot.wifiConnected ? "#30D158" : "#8E8E93"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Bagian Atas: Tanggal & Jam Besar
                Column {
                    anchors.top: parent.top
                    anchors.topMargin: Math.max(76, parent.height * 0.11)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(lockSurface.nowDate, "dddd, d MMMM")
                        color: "#EBFFFFFF"
                        font.pixelSize: 23
                        font.weight: Font.DemiBold
                        style: Text.Raised
                        styleColor: "#40000000"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(lockSurface.nowDate, "HH:mm")
                        color: "#F7FFFFFF"
                        font.pixelSize: 96
                        font.weight: Font.Bold
                        font.letterSpacing: -2.5
                        style: Text.Raised
                        styleColor: "#4D000000"
                    }
                }

                // Bagian Bawah: Avatar Profil, Nama Akun, & Kapsul Password
                Column {
                    id: bottomColumn
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.max(64, parent.height * 0.10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    // Avatar Bulat (diatur belakangan)
                    Item {
                        width: 78
                        height: 78
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            id: avatarClipMask
                            anchors.fill: parent
                            radius: 39
                            visible: false
                        }

                        Image {
                            id: userAvatarImg
                            anchors.fill: parent
                            source: "file://" + lockSurface.avatarPath
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: userAvatarImg
                            maskEnabled: true
                            maskSource: avatarClipMask
                            visible: userAvatarImg.status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 39
                            visible: userAvatarImg.status !== Image.Ready
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#5AC8FA" }
                                GradientStop { position: 1.0; color: "#007AFF" }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: lockSurface.displayName.charAt(0)
                                color: "#FFFFFF"
                                font.pixelSize: 32
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 39
                            color: "transparent"
                            border.width: 1.5
                            border.color: "#4DFFFFFF"
                        }
                    }

                    // Nama User
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: lockSurface.displayName
                        color: "#F5FFFFFF"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        style: Text.Raised
                        styleColor: "#40000000"
                    }

                    // Kapsul Input Password (Lebar tetap agar koordinat huruf stabil 100%)
                    Item {
                        id: pillWrapper
                        width: 244
                        height: 40
                        anchors.horizontalCenter: parent.horizontalCenter

                        property real shakeOffset: 0
                        transform: Translate { x: pillWrapper.shakeOffset }

                        SequentialAnimation {
                            id: shakeAnim
                            NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: -10; duration: 55; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: 10; duration: 65; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: -7; duration: 55; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: 7; duration: 55; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: 0; duration: 50; easing.type: Easing.OutQuad }
                        }

                        // Background Kapsul Kaca Jernih
                        Rectangle {
                            id: pillGlass
                            anchors.fill: parent
                            radius: height * 0.5
                            color: lockSurface.errorText !== ""
                                ? "#2EFF453A"
                                : (passwordInput.text.length > 0 ? "#24FFFFFF" : "#1CFFFFFF")
                            border.width: (passwordInput.activeFocus || passwordInput.text.length > 0) ? 1.25 : 1.0
                            border.color: lockSurface.errorText !== ""
                                ? "#D9FF453A"
                                : (passwordInput.text.length > 0 ? "#8CFFFFFF" : "#4DFFFFFF")

                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            // Progress bar verifikasi PAM di dalam kapsul
                            Rectangle {
                                width: 78
                                height: 2
                                radius: 1
                                color: "#E6FFFFFF"
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                visible: lockSurface.authenticating
                                x: 18

                                SequentialAnimation on x {
                                    running: lockSurface.authenticating
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 18; to: pillGlass.width - 96; duration: 720; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: pillGlass.width - 96; to: 18; duration: 720; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        // Klik pada kapsul hanya memfokuskan kolom password
                        MouseArea {
                            anchors.fill: parent
                            onPressed: passwordInput.forceActiveFocus()
                        }

                        // Label Placeholder
                        Text {
                            y: (parent.height - height) * 0.5
                            x: passwordInput.text.length === 0 ? 17 : 25
                            opacity: passwordInput.text.length === 0 ? 1.0 : 0.0
                            text: lockSurface.authenticating ? "Memverifikasi..." : "Enter Password"
                            color: "#B8FFFFFF"
                            font.pixelSize: 13
                            font.weight: Font.Medium

                            Behavior on x {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
                            }
                        }

                        // Input Keyboard Native (Kursor bawaan hitam dimatikan total via cursorDelegate)
                        TextInput {
                            id: passwordInput
                            anchors.left: parent.left
                            anchors.leftMargin: 17
                            anchors.right: submitBtn.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"
                            cursorVisible: false
                            cursorDelegate: Item { width: 0; height: 0; visible: false }
                            selectionColor: "transparent"
                            selectedTextColor: "transparent"
                            font.pixelSize: 14
                            echoMode: TextInput.Password
                            clip: true
                            focus: true
                            enabled: !lockSurface.authenticating

                            onAccepted: lockSurface.submitPassword()
                            Keys.onReturnPressed: lockSurface.submitPassword()
                            Keys.onEnterPressed: lockSurface.submitPassword()
                            Keys.onEscapePressed: {
                                text = "";
                                lockSurface.errorText = "";
                            }
                            onTextEdited: {

                                let len = text.length;

                                let totalW = len > 0 ? (len * 9.5 + (len - 1) * 5.0) : 0;

                                let targetX = len > 0

                                    ? Math.min(dotsViewport.width - 4.75, totalW - 4.75)

                                    : 4.75;

                                let pt = dotsViewport.mapToItem(waterShader, targetX, dotsViewport.height * 0.5);

                                lockSurface.spawnLiquidAt(pt.x, pt.y, 1.05);

                            }

                            onTextChanged: {
                                if (text.length > 0 && lockSurface.errorText !== "") {
                                    lockSurface.errorText = "";
                                }
                            }
                        }

                        // Visualizer Titik Password (Riak air muncul tepat di posisi titik huruf yang baru keluar)
                        Item {
                            id: dotsViewport
                            anchors.left: parent.left
                            anchors.leftMargin: 17
                            anchors.right: submitBtn.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            height: 22
                            clip: true

                            Row {
                                id: dotsRow
                                height: parent.height
                                spacing: 5
                                x: Math.min(0, dotsViewport.width - width)

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                    }
                                }

                                Repeater {
                                    model: passwordInput.text.length

                                    delegate: Item {
                                        id: dotSlot
                                        width: 9.5
                                        height: 22

                                        Component.onCompleted: dotAppearAnim.start()

                                        Rectangle {
                                            id: dotGlyph
                                            anchors.centerIn: parent
                                            width: 8
                                            height: 8
                                            radius: 4
                                            color: "#F5FFFFFF"
                                            scale: 0.2
                                            opacity: 0.0
                                        }

                                        ParallelAnimation {
                                            id: dotAppearAnim
                                            NumberAnimation {
                                                target: dotGlyph
                                                property: "opacity"
                                                from: 0.0
                                                to: 1.0
                                                duration: 130
                                                easing.type: Easing.OutQuad
                                            }
                                            SequentialAnimation {
                                                NumberAnimation {
                                                    target: dotGlyph
                                                    property: "scale"
                                                    from: 0.2
                                                    to: 1.22
                                                    duration: 140
                                                    easing.type: Easing.BezierSpline
                                                    easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                                }
                                                NumberAnimation {
                                                    target: dotGlyph
                                                    property: "scale"
                                                    from: 1.22
                                                    to: 1.0
                                                    duration: 140
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Satu-satunya kursor putih halus di ujung titik password
                            Rectangle {
                                id: materialCaret
                                width: 1.8
                                height: 15
                                radius: 0.9
                                color: "#EBFFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.min(dotsViewport.width - width, dotsRow.x + dotsRow.width + (passwordInput.text.length > 0 ? 4 : 0))
                                visible: passwordInput.activeFocus && !lockSurface.authenticating

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                    }
                                }

                                SequentialAnimation on opacity {
                                    running: materialCaret.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.9; to: 0.2; duration: 540; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 0.2; to: 0.9; duration: 540; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        // Tombol Submit Panah (Dapat diklik langsung dengan touchpad maupun Enter)
                        Rectangle {
                            id: submitBtn
                            width: 28
                            height: 28
                            radius: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            z: 20

                            property bool activeShow: passwordInput.text.length > 0 && !lockSurface.authenticating
                            visible: activeShow
                            opacity: activeShow ? 1.0 : 0.0
                            scale: submitMouse.pressed ? 0.88 : 1.0
                            color: submitMouse.pressed ? "#66FFFFFF" : (submitMouse.containsMouse ? "#4DFFFFFF" : "#38FFFFFF")
                            border.width: 1
                            border.color: "#66FFFFFF"

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                }
                            }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "→"
                                color: "#FFFFFF"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: submitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: lockSurface.submitPassword()
                            }
                        }
                    }

                    // Pesan Error / Petunjuk Bawah
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: lockSurface.errorText !== ""
                            ? lockSurface.errorText
                            : "Enter Password to Unlock"
                        color: lockSurface.errorText !== "" ? "#FF6961" : "#B3FFFFFF"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        style: Text.Raised
                        styleColor: "#40000000"
                    }
                }
            }
        }
    }
}
