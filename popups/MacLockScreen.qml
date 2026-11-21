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

            function submitPassword() {
                if (authenticating) return;
                if (passwordInput.text.length === 0) {
                    triggerShake();
                    return;
                }
                pillContainer.spawnWaterRipple(pillContainer.width * 0.5, pillContainer.height * 0.5, true);
                screenWaveLayer.spawnScreenWave(pillWrapper.x + pillWrapper.width * 0.5, bottomColumn.y + pillWrapper.y + pillWrapper.height * 0.5);

                pendingPassword = passwordInput.text;
                authenticating = true;
                errorText = "";

                if (pam.active && pam.responseRequired) {
                    let pw = pendingPassword;
                    pendingPassword = "";
                    pam.respond(pw);
                } else {
                    if (pam.active) pam.abort();
                    pam.start();
                }
            }

            Component.onCompleted: {
                passwordInput.forceActiveFocus();
                pam.start();
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: lockSurface.nowDate = new Date()
            }

            PamContext {
                id: pam
                config: "system-auth"
                user: lockSurface.userName

                onResponseRequiredChanged: {
                    if (pam.responseRequired && lockSurface.pendingPassword !== "") {
                        let pw = lockSurface.pendingPassword;
                        lockSurface.pendingPassword = "";
                        pam.respond(pw);
                    }
                }

                onPamMessage: {
                    if (pam.messageIsError && pam.message !== "") {
                        lockSurface.errorText = pam.message;
                    }
                }

                onCompleted: (result) => {
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
                        pam.start();
                    }
                }

                onError: (err) => {
                    lockSurface.authenticating = false;
                    lockSurface.pendingPassword = "";
                    lockSurface.errorText = "Autentikasi gagal (" + PamError.toString(err) + ")";
                    lockSurface.triggerShake();
                    passwordInput.forceActiveFocus();
                }
            }

            // Latar Wallpaper Aktif
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

            // Efek Frosted Blur ala macOS Lock Screen
            MultiEffect {
                anchors.fill: lockWallpaper
                source: lockWallpaper
                blurEnabled: true
                blur: 0.68
                blurMax: 52
                autoPaddingEnabled: false
            }

            // Fallback gelap jika wallpaper belum termuat
            Rectangle {
                anchors.fill: parent
                color: "#111318"
                visible: lockWallpaper.status !== Image.Ready
            }

            // Vignette lembut agar jam dan teks putih tetap kontras
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#4D000000" }
                    GradientStop { position: 0.45; color: "#26000000" }
                    GradientStop { position: 1.0; color: "#66000000" }
                }
            }

            // Gelombang Riak Air Layar Penuh saat Sentuh / Klik
            Item {
                id: screenWaveLayer
                anchors.fill: parent
                clip: true

                property int nextSlot: 0
                function spawnScreenWave(wx, wy) {
                    let item = screenWaveRepeater.itemAt(nextSlot);
                    nextSlot = (nextSlot + 1) % 4;
                    if (item) item.trigger(wx, wy);
                }

                Repeater {
                    id: screenWaveRepeater
                    model: 4
                    delegate: Item {
                        id: swItem
                        width: 460
                        height: 460
                        opacity: 0.0
                        scale: 0.03
                        visible: opacity > 0.002

                        function trigger(cx, cy) {
                            x = cx - width * 0.5;
                            y = cy - height * 0.5;
                            swAnim.restart();
                        }

                        // Cincin gelombang luar
                        Rectangle {
                            anchors.fill: parent
                            radius: width * 0.5
                            color: "transparent"
                            border.width: 1.5
                            border.color: "#59FFFFFF"
                        }

                        // Cincin gelombang sekunder
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.66
                            height: width
                            radius: width * 0.5
                            color: "#0DFFFFFF"
                            border.width: 1.0
                            border.color: "#38FFFFFF"
                        }

                        ParallelAnimation {
                            id: swAnim
                            NumberAnimation {
                                target: swItem
                                property: "scale"
                                from: 0.03
                                to: 1.0
                                duration: 920
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                            }
                            SequentialAnimation {
                                NumberAnimation {
                                    target: swItem
                                    property: "opacity"
                                    from: 0.0
                                    to: 0.65
                                    duration: 140
                                    easing.type: Easing.OutQuad
                                }
                                NumberAnimation {
                                    target: swItem
                                    property: "opacity"
                                    from: 0.65
                                    to: 0.0
                                    duration: 780
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }

            // Sentuh di mana saja langsung memfokuskan password & memicu riak air di titik sentuh
            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => {
                    passwordInput.forceActiveFocus();
                    screenWaveLayer.spawnScreenWave(mouse.x, mouse.y);
                }
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

            // Bagian Bawah: Avatar Profil (dibiarkan default dulu), Nama Akun, & Kapsul Password Material
            Column {
                id: bottomColumn
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.max(64, parent.height * 0.10)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                // Avatar Bulat
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

                // Kapsul Input Password Android Material + Overlapping Water Ripples
                Item {
                    id: pillWrapper
                    width: passwordInput.text.length > 0 ? 256 : 230
                    height: 42
                    anchors.horizontalCenter: parent.horizontalCenter

                    Behavior on width {
                        NumberAnimation {
                            duration: 320
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        }
                    }

                    property real shakeOffset: 0
                    property real touchScale: pillTouchArea.pressed ? 0.975 : 1.0
                    scale: touchScale
                    Behavior on touchScale {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        }
                    }
                    transform: Translate { x: pillWrapper.shakeOffset }

                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: -10; duration: 55; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: 10; duration: 65; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: -7; duration: 55; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: 7; duration: 55; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: pillWrapper; property: "shakeOffset"; to: 0; duration: 50; easing.type: Easing.OutQuad }
                    }

                    // Container Kapsul dengan Pool 8 Gelombang Riak Air Independen
                    Rectangle {
                        id: pillContainer
                        anchors.fill: parent
                        radius: 21
                        clip: true
                        color: lockSurface.errorText !== ""
                            ? "#38FF453A"
                            : (passwordInput.text.length > 0 ? "#47FFFFFF" : "#33FFFFFF")
                        border.width: (passwordInput.activeFocus || passwordInput.text.length > 0) ? 1.5 : 1.0
                        border.color: lockSurface.errorText !== ""
                            ? "#E6FF453A"
                            : (passwordInput.text.length > 0 ? "#BFFFFFFF" : "#59FFFFFF")

                        Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }

                        property int rippleSlot: 0
                        function spawnWaterRipple(rx, ry, strong) {
                            let item = capsuleRippleRepeater.itemAt(rippleSlot);
                            rippleSlot = (rippleSlot + 1) % 8;
                            if (item) item.trigger(rx, ry, strong);
                        }

                        // Pool 8 Ripple GPU (tidak saling memotong saat ketik cepat)
                        Repeater {
                            id: capsuleRippleRepeater
                            model: 8

                            delegate: Item {
                                id: capRipple
                                width: 320
                                height: 320
                                opacity: 0.0
                                scale: 0.03
                                visible: opacity > 0.002
                                property bool isStrong: false

                                function trigger(cx, cy, strong) {
                                    isStrong = strong;
                                    x = cx - width * 0.5;
                                    y = cy - height * 0.5;
                                    capRippleAnim.restart();
                                }

                                // Gelombang luar lembut (water crest)
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width * 0.5
                                    color: capRipple.isStrong ? "#249BE7FF" : "#1AFFFFFF"
                                    border.width: 1.6
                                    border.color: capRipple.isStrong ? "#80B8F0FF" : "#59FFFFFF"
                                }

                                // Gelombang dalam sekunder
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.62
                                    height: width
                                    radius: width * 0.5
                                    color: capRipple.isStrong ? "#26B8F0FF" : "#1FFFFFFF"
                                    border.width: 1.1
                                    border.color: "#45FFFFFF"
                                }

                                // Inti cahaya sentuhan
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.28
                                    height: width
                                    radius: width * 0.5
                                    color: "#33FFFFFF"
                                }

                                ParallelAnimation {
                                    id: capRippleAnim
                                    NumberAnimation {
                                        target: capRipple
                                        property: "scale"
                                        from: 0.03
                                        to: 1.0
                                        duration: capRipple.isStrong ? 760 : 680
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                    }
                                    SequentialAnimation {
                                        NumberAnimation {
                                            target: capRipple
                                            property: "opacity"
                                            from: 0.0
                                            to: capRipple.isStrong ? 0.95 : 0.78
                                            duration: 110
                                            easing.type: Easing.OutQuad
                                        }
                                        NumberAnimation {
                                            target: capRipple
                                            property: "opacity"
                                            from: capRipple.isStrong ? 0.95 : 0.78
                                            to: 0.0
                                            duration: capRipple.isStrong ? 650 : 570
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }
                        }

                        // Indeterminate Material progress bar saat PAM memverifikasi
                        Item {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2.5
                            visible: lockSurface.authenticating

                            Rectangle {
                                width: 84
                                height: parent.height
                                radius: 1.25
                                color: "#FFFFFF"
                                x: -84

                                SequentialAnimation on x {
                                    running: lockSurface.authenticating
                                    loops: Animation.Infinite
                                    NumberAnimation { from: -84; to: 260; duration: 760; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }

                    // Area sentuh pada kapsul memicu riak air tepat di koordinat jari/kursor
                    MouseArea {
                        id: pillTouchArea
                        anchors.fill: parent
                        onPressed: (mouse) => {
                            passwordInput.forceActiveFocus();
                            pillContainer.spawnWaterRipple(mouse.x, mouse.y, false);
                            screenWaveLayer.spawnScreenWave(pillWrapper.x + mouse.x, bottomColumn.y + pillWrapper.y + mouse.y);
                        }
                    }

                    // Label Placeholder dengan Transisi Material 3
                    Text {
                        id: placeholderLabel
                        y: (parent.height - height) * 0.5
                        x: passwordInput.text.length === 0 ? 17 : 28
                        opacity: passwordInput.text.length === 0 ? 1.0 : 0.0
                        text: lockSurface.authenticating ? "Memverifikasi..." : "Enter Password"
                        color: "#B8FFFFFF"
                        font.pixelSize: 13
                        font.weight: Font.Medium

                        Behavior on x {
                            NumberAnimation {
                                duration: 240
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
                        }
                    }

                    // Input Keyboard Native
                    TextInput {
                        id: passwordInput
                        anchors.left: parent.left
                        anchors.leftMargin: 17
                        anchors.right: submitBtn.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        cursorVisible: false
                        selectionColor: "transparent"
                        selectedTextColor: "transparent"
                        font.pixelSize: 14
                        echoMode: TextInput.Password
                        clip: true
                        focus: true
                        enabled: !lockSurface.authenticating

                        Keys.onReturnPressed: lockSurface.submitPassword()
                        Keys.onEnterPressed: lockSurface.submitPassword()
                        Keys.onEscapePressed: {
                            text = "";
                            lockSurface.errorText = "";
                        }
                        onTextEdited: {
                            let spawnX = Math.min(pillContainer.width - 36, 17 + dotsRow.width + 6);
                            pillContainer.spawnWaterRipple(spawnX, pillContainer.height * 0.5, false);
                        }
                        onTextChanged: {
                            if (text.length > 0 && lockSurface.errorText !== "") {
                                lockSurface.errorText = "";
                            }
                        }
                    }

                    // Visualizer Titik Password Android Material You (Smooth Morph & Halo)
                    Item {
                        id: dotsViewport
                        anchors.left: parent.left
                        anchors.leftMargin: 17
                        anchors.right: submitBtn.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        height: 24
                        clip: true

                        Row {
                            id: dotsRow
                            height: parent.height
                            spacing: 5
                            x: Math.min(0, dotsViewport.width - width)

                            Behavior on x {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                }
                            }

                            Repeater {
                                model: passwordInput.text.length

                                delegate: Item {
                                    id: dotSlot
                                    width: 0
                                    height: 24

                                    Component.onCompleted: dotAppearAnim.start()

                                    // Halo riak mini di sekitar titik yang baru diketik
                                    Rectangle {
                                        id: dotHalo
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: "#33FFFFFF"
                                        border.width: 1
                                        border.color: "#73FFFFFF"
                                        scale: 0.2
                                        opacity: 0.0
                                    }

                                    // Glyph titik Material (squircle-to-circle smooth expansion)
                                    Rectangle {
                                        id: dotGlyph
                                        anchors.centerIn: parent
                                        width: 8.5
                                        height: 8.5
                                        radius: 4.25
                                        color: "#FFFFFF"
                                        scale: 0.15
                                        opacity: 0.0
                                    }

                                    ParallelAnimation {
                                        id: dotAppearAnim
                                        NumberAnimation {
                                            target: dotSlot
                                            property: "width"
                                            from: 0
                                            to: 10
                                            duration: 220
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                        }
                                        NumberAnimation {
                                            target: dotGlyph
                                            property: "opacity"
                                            from: 0.0
                                            to: 1.0
                                            duration: 140
                                            easing.type: Easing.OutQuad
                                        }
                                        NumberAnimation {
                                            target: dotGlyph
                                            property: "radius"
                                            from: 2.0
                                            to: 4.25
                                            duration: 260
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                        }
                                        SequentialAnimation {
                                            NumberAnimation {
                                                target: dotGlyph
                                                property: "scale"
                                                from: 0.15
                                                to: 1.24
                                                duration: 165
                                                easing.type: Easing.BezierSpline
                                                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                            }
                                            NumberAnimation {
                                                target: dotGlyph
                                                property: "scale"
                                                from: 1.24
                                                to: 1.0
                                                duration: 155
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                        // Animasi halo gelombang mini di tiap karakter
                                        NumberAnimation {
                                            target: dotHalo
                                            property: "scale"
                                            from: 0.25
                                            to: 1.15
                                            duration: 420
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                        }
                                        SequentialAnimation {
                                            NumberAnimation {
                                                target: dotHalo
                                                property: "opacity"
                                                from: 0.0
                                                to: 0.75
                                                duration: 90
                                                easing.type: Easing.OutQuad
                                            }
                                            NumberAnimation {
                                                target: dotHalo
                                                property: "opacity"
                                                from: 0.75
                                                to: 0.0
                                                duration: 330
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Kursor garis halus mengikuti ujung titik dengan gerakan gliding
                        Rectangle {
                            id: materialCaret
                            width: 2.0
                            height: 16
                            radius: 1.0
                            color: "#F2FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.min(dotsViewport.width - width, dotsRow.x + dotsRow.width + (passwordInput.text.length > 0 ? 4 : 0))
                            visible: passwordInput.activeFocus && !lockSurface.authenticating

                            Behavior on x {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                }
                            }

                            SequentialAnimation on opacity {
                                running: materialCaret.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.95; to: 0.18; duration: 540; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 0.18; to: 0.95; duration: 540; easing.type: Easing.InOutSine }
                            }
                        }
                    }

                    // Tombol Submit Panah Material 3
                    Rectangle {
                        id: submitBtn
                        width: 28
                        height: 28
                        radius: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter

                        property bool activeShow: passwordInput.text.length > 0 && !lockSurface.authenticating
                        visible: opacity > 0.01
                        opacity: activeShow ? 1.0 : 0.0
                        scale: activeShow ? (submitMouse.pressed ? 0.86 : 1.0) : 0.35
                        color: submitMouse.pressed ? "#73FFFFFF" : (submitMouse.containsMouse ? "#52FFFFFF" : "#3DFFFFFF")
                        border.width: 1
                        border.color: "#66FFFFFF"

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: "→"
                            color: "#FFFFFF"
                            font.pixelSize: 14
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
