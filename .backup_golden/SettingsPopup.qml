import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../core"

Item {
    id: settingsScope
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin
    readonly property real cardOpacity: settingsCard.opacity

    property bool showWallpaperAdvanced: false

    Process {
        id: settingsExtraProc
        Component.onCompleted: running = true
        command: ["sh", "-c", "ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}'); [ -z \"$ip_addr\" ] && ip_addr='Offline'; pprof=$(powerprofilesctl get 2>/dev/null || echo 'balanced'); printf '%s|%s\n' \"$ip_addr\" \"$pprof\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split("|");
                if (p.length >= 2) {
                    shellRoot.localIpAddr = p[0];
                    shellRoot.powerProfile = p[1];
                }
            }
        }
    }

    property int batHealthPct: 98
    property int batCycleCount: 0
    property string batTech: "Li-ion"
    property string lowPowerPolicy: "battery"
    property string batChartRange: "24h"
    property var batHistory24h: [78,76,74,72,70,68,65,62,59,56,54,52,49,46,43,40,38,35,52,74,91,96,94,92]
    property var batHistory10d: [88,82,91,76,84,79,93,85,81,89]
    property var screenHistory24h: [0,0,0,0,0,0,12,28,45,52,38,41,55,60,48,35,22,44,58,50,36,29,18,14]
    property var screenHistory10d: [310,285,340,260,390,325,410,295,350,240]
    property string screenOnSummary: "4j 32m sesi aktif"

    property real storageTotalGb: 256.0
    property real storageUsedGb: 94.0
    property real storageSysGb: 38.0
    property real storageAppsGb: 26.0
    property real storageMediaGb: 30.0

    property bool tpNaturalScroll: true
    property bool tpTapToClick: true
    property bool tpDisableWhileTyping: true
    property bool tpLeftHanded: false
    property real tpAccelSpeed: 0.20
    property string tpAccelProfile: "adaptive"
    property real tpScrollFactor: 1.0

    property real msAccelSpeed: 0.0
    property string msAccelProfile: "flat"
    property bool msNaturalScroll: false
    property bool msLeftHanded: false
    property bool msMiddleEmulation: false
    property real msScrollFactor: 1.0

    property int kbRepeatDelay: 300
    property int kbRepeatRate: 35
    property bool niriFocusFollowsMouse: false
    property bool niriWarpMouseToFocus: false
    property string niriInputFeedback: ""
    property var niriBindsList: []
    property string newBindCombo: ""
    property string newBindCmd: ""

    property bool islandEnabled: true
    property bool islandMusicHover: true
    property string islandMode: "adaptive"
    property int notifDurationSec: 4
    property string notifTestBanner: ""

    Process {
        id: hwTelemetryProc
        Component.onCompleted: running = true
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/hw_telemetry.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split("|");
                if (p.length >= 9) {
                    settingsScope.batHealthPct = parseInt(p[0]) || 98;
                    settingsScope.batCycleCount = parseInt(p[1]) || 0;
                    settingsScope.batTech = p[2] || "Li-ion";
                    settingsScope.screenOnSummary = p[3] || "2j 15m sesi aktif";
                    settingsScope.storageTotalGb = parseFloat(p[4]) || 256.0;
                    settingsScope.storageUsedGb = parseFloat(p[5]) || 94.0;
                    settingsScope.storageSysGb = parseFloat(p[6]) || 38.0;
                    settingsScope.storageAppsGb = parseFloat(p[7]) || 26.0;
                    settingsScope.storageMediaGb = parseFloat(p[8]) || 30.0;
                }
            }
        }
    }

    Process {
        id: niriStateReaderProc
        Component.onCompleted: running = true
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/niri_config_helper.py", "read_state"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim().split("|");
                if (p.length >= 17) {
                    settingsScope.tpTapToClick = (p[0] === "1");
                    settingsScope.tpNaturalScroll = (p[1] === "1");
                    settingsScope.tpDisableWhileTyping = (p[2] === "1");
                    settingsScope.tpLeftHanded = (p[3] === "1");
                    settingsScope.tpAccelSpeed = parseFloat(p[4]) || 0.2;
                    settingsScope.tpAccelProfile = p[5] || "adaptive";
                    settingsScope.tpScrollFactor = parseFloat(p[6]) || 1.0;
                    settingsScope.msAccelSpeed = parseFloat(p[7]) || 0.0;
                    settingsScope.msAccelProfile = p[8] || "flat";
                    settingsScope.msNaturalScroll = (p[9] === "1");
                    settingsScope.msLeftHanded = (p[10] === "1");
                    settingsScope.msMiddleEmulation = (p[11] === "1");
                    settingsScope.msScrollFactor = parseFloat(p[12]) || 1.0;
                    settingsScope.kbRepeatDelay = parseInt(p[13]) || 300;
                    settingsScope.kbRepeatRate = parseInt(p[14]) || 35;
                    settingsScope.niriFocusFollowsMouse = (p[15] === "1");
                    settingsScope.niriWarpMouseToFocus = (p[16] === "1");
                }
            }
        }
    }

    Process {
        id: niriBindsReaderProc
        Component.onCompleted: running = true
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/niri_config_helper.py", "read_binds"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rows = text.trim().split("\n").filter(l => l.includes("|"));
                let arr = [];
                for (let i = 0; i < rows.length; i++) {
                    let parts = rows[i].split("|");
                    arr.push({ combo: parts[0], action: parts.slice(1).join("|") });
                }
                settingsScope.niriBindsList = arr;
            }
        }
    }

    function applyNiriInputConfig() {
        let args = [
            tpTapToClick ? "1" : "0",
            tpNaturalScroll ? "1" : "0",
            tpDisableWhileTyping ? "1" : "0",
            tpLeftHanded ? "1" : "0",
            tpAccelSpeed.toFixed(2),
            tpAccelProfile,
            tpScrollFactor.toFixed(2),
            msAccelSpeed.toFixed(2),
            msAccelProfile,
            msNaturalScroll ? "1" : "0",
            msLeftHanded ? "1" : "0",
            msMiddleEmulation ? "1" : "0",
            msScrollFactor.toFixed(2),
            String(Math.round(kbRepeatDelay)),
            String(Math.round(kbRepeatRate)),
            niriFocusFollowsMouse ? "1" : "0",
            niriWarpMouseToFocus ? "1" : "0"
        ];
        shellRoot.runCmd("python3 ~/.config/quickshell/scripts/niri_config_helper.py set_full " + args.join(" "));
        niriInputFeedback = "Tersimpan ke ~/.config/niri/config.kdl";
        niriFeedbackClearTimer.restart();
    }

    function addNiriCustomBind() {
        let c = newBindCombo.trim().replace(/'/g, "");
        let a = newBindCmd.trim().replace(/'/g, "");
        if (c === "" || a === "") return;
        shellRoot.runCmd("python3 ~/.config/quickshell/scripts/niri_config_helper.py add_bind '" + c + "' '" + a + "'");
        newBindCombo = "";
        newBindCmd = "";
        niriBindsReaderProc.running = false;
        niriBindsReaderProc.running = true;
    }

    Timer {
        id: niriFeedbackClearTimer
        interval: 2600
        repeat: false
        onTriggered: settingsScope.niriInputFeedback = ""
    }

    Timer {
        id: notifBannerClearTimer
        interval: Math.max(1500, settingsScope.notifDurationSec * 1000)
        repeat: false
        onTriggered: settingsScope.notifTestBanner = ""
    }

    function setPowerProfile(prof) {
        shellRoot.powerProfile = prof;
        shellRoot.runCmd("powerprofilesctl set " + prof + " 2>/dev/null || true");
    }

    // Komponen Switch macOS Clean
    component MacSwitch: Rectangle {
        id: swRoot
        property bool checked: false
        signal toggled()

        width: 42
        height: 24
        radius: 12
        color: checked ? ThemeTokens.accent : (ThemeTokens.isDark ? "#3A3A3C" : "#D1D1D6")
        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Rectangle {
            width: 20
            height: 20
            radius: 10
            y: 2
            x: swRoot.checked ? 20 : 2
            color: "#FFFFFF"
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: swRoot.toggled()
        }
    }

    // Komponen Slider macOS Clean
    component MacSlider: Item {
        id: slRoot
        property real value: 0.5
        property real minVal: 0.0
        property real maxVal: 1.0
        property bool enabledControl: true
        signal moved(real newValue)

        implicitHeight: 24
        opacity: enabledControl ? 1.0 : 0.45

        readonly property real ratio: Math.max(0.0, Math.min(1.0, (value - minVal) / Math.max(0.0001, maxVal - minVal)))

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 5
            radius: 2.5
            color: ThemeTokens.isDark ? "#3A3A3C" : "#D1D1D6"

            Rectangle {
                width: track.width * slRoot.ratio
                height: parent.height
                radius: 2.5
                color: ThemeTokens.accent
                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, track.width * slRoot.ratio - width * 0.5))
            color: "#FFFFFF"
            border.width: 1
            border.color: ThemeTokens.isDark ? "#48484A" : "#C7C7CC"
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: slRoot.enabledControl
            cursorShape: Qt.PointingHandCursor
            function updateFromX(mx) {
                let r = Math.max(0.0, Math.min(1.0, mx / Math.max(1, width)));
                slRoot.moved(slRoot.minVal + r * (slRoot.maxVal - slRoot.minVal));
            }
            onPressed: (m) => updateFromX(m.x)
            onPositionChanged: (m) => { if (pressed) updateFromX(m.x); }
        }
    }

    // Komponen Grup Kartu macOS Settings
    component SettingsGroup: Rectangle {
        default property alias groupContent: innerCol.data
        Layout.fillWidth: true
        implicitHeight: innerCol.implicitHeight + 24
        radius: 14
        color: ThemeTokens.cardBg
        border.width: 1
        border.color: ThemeTokens.borderSubtle

        ColumnLayout {
            id: innerCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10
        }
    }

    Rectangle {
        id: settingsCard
        z: 17
        anchors.centerIn: parent
        width: 820
        height: 610
        radius: 22
        color: ThemeTokens.windowBg
        border.width: 1
        border.color: ThemeTokens.borderStrong
        clip: true
        visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "settings" || opacity > 0.01)

        MouseArea { anchors.fill: parent; z: 0 }

        // Canvas latar aktif saat mode Liquid; tidak dirender berlebihan saat Solid
        GlassPanel {
            anchors.fill: parent
            z: 0
            radius: 22
            visible: !ShellState.isSolid
            drawRim: false
        }

        property bool _mounted: false
        Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
        property bool isOpen: _mounted && (shellRoot.activePopup === "settings")

        onIsOpenChanged: {
            if (isOpen) {
                settingsKeyCatcher.forceActiveFocus();
            }
        }

        property string activeNavPane: "left"
        property int rightFocusIdx: 0
        property var rightControls: []
        readonly property var navTabOrder: ["appearance", "wallpaper", "display_sound", "input_shortcuts", "notifications_island", "wifi", "bluetooth", "power", "language_profile"]

        function isSwitchControl(item) {
            return item && typeof item.checked === "boolean" && typeof item.toggled === "function";
        }

        function isSliderControl(item) {
            return item && typeof item.minVal === "number" && typeof item.maxVal === "number" && typeof item.value === "number";
        }

        function findClickableMouseArea(item) {
            if (!item || !item.children) return null;
            for (let i = 0; i < item.children.length; i++) {
                let c = item.children[i];
                if (c && String(c).indexOf("MouseArea") !== -1 && c.enabled && c.visible) {
                    return c;
                }
            }
            return null;
        }

        function collectVisibleControls(item, out) {
            if (!item || !item.visible || item.opacity <= 0.05) return;
            if (isSwitchControl(item) || isSliderControl(item)) {
                if (item.width >= 32 && item.height >= 18) {
                    out.push(item);
                    return;
                }
            }
            let ma = findClickableMouseArea(item);
            if (ma && item.width >= 40 && item.height >= 22 && item.height <= 96) {
                out.push(item);
                return;
            }
            if (item.children) {
                for (let i = 0; i < item.children.length; i++) {
                    collectVisibleControls(item.children[i], out);
                }
            }
        }

        function refreshRightControls() {
            let list = [];
            collectVisibleControls(rightCol, list);
            rightControls = list;
            if (rightFocusIdx >= list.length) rightFocusIdx = Math.max(0, list.length - 1);
            updateFocusRing();
        }

        function updateFocusRing() {
            if (activeNavPane !== "right" || rightControls.length === 0) {
                rightFocusRing.visible = false;
                return;
            }
            let target = rightControls[Math.max(0, Math.min(rightControls.length - 1, rightFocusIdx))];
            if (!target) { rightFocusRing.visible = false; return; }
            let pos = target.mapToItem(rightScroll.contentItem, 0, 0);
            let padX = isSliderControl(target) ? 8 : 5;
            let padY = isSliderControl(target) ? 3 : 5;
            rightFocusRing.targetX = pos.x - padX;
            rightFocusRing.targetY = pos.y - padY;
            rightFocusRing.targetW = target.width + padX * 2;
            rightFocusRing.targetH = target.height + padY * 2;
            rightFocusRing.targetR = Math.min(14, Math.round((target.height + padY * 2) / 2));
            rightFocusRing.visible = true;

            let viewTop = rightScroll.contentY;
            let viewBot = viewTop + rightScroll.height;
            let itemTop = pos.y - 24;
            let itemBot = pos.y + target.height + 24;
            let maxY = Math.max(0, rightScroll.contentHeight - rightScroll.height);
            if (itemTop < viewTop) {
                rightScrollAnim.stop();
                rightScrollAnim.from = rightScroll.contentY;
                rightScrollAnim.to = Math.max(0, itemTop);
                rightScrollAnim.start();
            } else if (itemBot > viewBot) {
                rightScrollAnim.stop();
                rightScrollAnim.from = rightScroll.contentY;
                rightScrollAnim.to = Math.min(maxY, itemBot - rightScroll.height);
                rightScrollAnim.start();
            }
        }

        function activateCurrentRightControl(stepDir) {
            if (rightControls.length === 0) return;
            let target = rightControls[Math.max(0, Math.min(rightControls.length - 1, rightFocusIdx))];
            if (!target) return;
            if (isSliderControl(target) && stepDir !== 0) {
                let span = (target.maxVal - target.minVal) || 100;
                let step = span >= 1000 ? 100 : 1;
                let nextVal = Math.max(target.minVal, Math.min(target.maxVal, Math.round(target.value) + step * stepDir));
                if (typeof target.moved === "function") target.moved(nextVal);
                return;
            }
            if (isSwitchControl(target) && stepDir === 0) {
                target.toggled();
                Qt.callLater(refreshRightControls);
                return;
            }
            if (stepDir === 0) {
                let ma = findClickableMouseArea(target);
                if (ma) {
                    ma.clicked({ button: Qt.LeftButton, x: Math.round(target.width / 2), y: Math.round(target.height / 2) });
                    Qt.callLater(refreshRightControls);
                }
            }
        }

        function stepSettingsTab(delta) {
            let idx = navTabOrder.indexOf(shellRoot.settingsTab);
            if (idx < 0) idx = 0;
            let next = (idx + delta + navTabOrder.length) % navTabOrder.length;
            shellRoot.settingsTab = navTabOrder[next];
            rightFocusIdx = 0;
            Qt.callLater(refreshRightControls);
        }

        NumberAnimation {
            id: rightScrollAnim
            target: rightScroll
            property: "contentY"
            duration: 210
            easing.type: Easing.OutExpo
        }

        Item {
            id: settingsKeyCatcher
            focus: settingsCard.isOpen && !setSearchInput.activeFocus && !setWifiPassField.activeFocus && !customMinInput.activeFocus && !customDirInput.activeFocus && !customFileInput.activeFocus && !profileNameInput.activeFocus && !profileAvatarInput.activeFocus
            Keys.onEscapePressed: {
                if (settingsCard.activeNavPane === "right") {
                    settingsCard.activeNavPane = "left";
                    settingsCard.updateFocusRing();
                } else {
                    shellRoot.closePopups();
                }
            }
            Keys.onUpPressed: (e) => {
                if (settingsCard.activeNavPane === "left") {
                    settingsCard.stepSettingsTab(-1);
                } else {
                    settingsCard.refreshRightControls();
                    if (settingsCard.rightControls.length > 0) {
                        settingsCard.rightFocusIdx = Math.max(0, settingsCard.rightFocusIdx - 1);
                        settingsCard.updateFocusRing();
                    }
                }
                e.accepted = true;
            }
            Keys.onDownPressed: (e) => {
                if (settingsCard.activeNavPane === "left") {
                    settingsCard.stepSettingsTab(1);
                } else {
                    settingsCard.refreshRightControls();
                    if (settingsCard.rightControls.length > 0) {
                        settingsCard.rightFocusIdx = Math.min(settingsCard.rightControls.length - 1, settingsCard.rightFocusIdx + 1);
                        settingsCard.updateFocusRing();
                    }
                }
                e.accepted = true;
            }
            Keys.onRightPressed: (e) => {
                if (settingsCard.activeNavPane === "left") {
                    settingsCard.activeNavPane = "right";
                    settingsCard.rightFocusIdx = 0;
                    settingsCard.refreshRightControls();
                } else {
                    settingsCard.activateCurrentRightControl(1);
                }
                e.accepted = true;
            }
            Keys.onLeftPressed: (e) => {
                if (settingsCard.activeNavPane === "right") {
                    let target = settingsCard.rightControls[settingsCard.rightFocusIdx];
                    if (settingsCard.isSliderControl(target)) {
                        settingsCard.activateCurrentRightControl(-1);
                    } else {
                        settingsCard.activeNavPane = "left";
                        settingsCard.updateFocusRing();
                    }
                    e.accepted = true;
                }
            }
            Keys.onReturnPressed: (e) => {
                if (settingsCard.activeNavPane === "left") {
                    settingsCard.activeNavPane = "right";
                    settingsCard.rightFocusIdx = 0;
                    settingsCard.refreshRightControls();
                } else {
                    settingsCard.activateCurrentRightControl(0);
                }
                e.accepted = true;
            }
            Keys.onSpacePressed: (e) => {
                if (settingsCard.activeNavPane === "right") {
                    settingsCard.activateCurrentRightControl(0);
                    e.accepted = true;
                }
            }
        }

        opacity: isOpen ? 1.0 : 0.0
        scale: isOpen ? 1.0 : 0.96
        transform: Translate {
            y: settingsCard.isOpen ? 0 : 12
            Behavior on y { SpringAnimation { mass: MotionEngine.floatMass; spring: MotionEngine.floatSpring; damping: MotionEngine.floatDamping; epsilon: MotionEngine.floatEpsilon } }
        }

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { SpringAnimation { mass: MotionEngine.floatMass; spring: MotionEngine.floatSpring; damping: MotionEngine.floatDamping; epsilon: MotionEngine.floatEpsilon } }

        RowLayout {
            anchors.fill: parent
            spacing: 0
            z: 2

            // ── SIDEBAR KIRI (MACOS SYSTEM SETTINGS) ─────────────────────
            Rectangle {
                Layout.preferredWidth: 232
                Layout.fillHeight: true
                Layout.leftMargin: 1
                Layout.topMargin: 1
                Layout.bottomMargin: 1
                topLeftRadius: 21
                bottomLeftRadius: 21
                color: ThemeTokens.sidebarBg
                border.width: settingsCard.activeNavPane === "left" ? 1 : 0
                border.color: ThemeTokens.accentSoft

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Traffic Lights + Judul
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Row {
                            spacing: 7
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                color: closeSetM.containsMouse ? "#FF3B30" : "#FF5F56"
                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: "#4D0000"
                                    font.pixelSize: 10
                                    font.bold: true
                                    visible: closeSetM.containsMouse
                                }
                                MouseArea {
                                    id: closeSetM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.closePopups()
                                }
                            }
                            Rectangle { width: 12; height: 12; radius: 6; color: "#FFBD2E" }
                            Rectangle { width: 12; height: 12; radius: 6; color: "#27C93F" }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: LocaleStrings.settingsTitle
                            color: ThemeTokens.textSecondary
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    // Search Bar macOS
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: ThemeTokens.inputBg
                        border.width: 1
                        border.color: setSearchInput.activeFocus ? ThemeTokens.accent : ThemeTokens.borderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: "⌕"
                                color: ThemeTokens.textSecondary
                                font.pixelSize: 13
                            }

                            TextInput {
                                id: setSearchInput
                                Layout.fillWidth: true
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 12
                                clip: true
                                onTextChanged: {
                                    shellRoot.settingsSearch = text;
                                    let q = text.toLowerCase().trim();
                                    if (q === "") return;
                                    if (q.includes("wifi") || q.includes("net") || q.includes("ip")) shellRoot.settingsTab = "wifi";
                                    else if (q.includes("blue") || q.includes("bt")) shellRoot.settingsTab = "bluetooth";
                                    else if (q.includes("wall") || q.includes("gacha") || q.includes("live")) shellRoot.settingsTab = "wallpaper";
                                    else if (q.includes("bright") || q.includes("sound") || q.includes("vol") || q.includes("audio") || q.includes("dnd")) shellRoot.settingsTab = "display_sound";
                                    else if (q.includes("solid") || q.includes("liquid") || q.includes("dark") || q.includes("light") || q.includes("dock") || q.includes("float") || q.includes("island") || q.includes("notch")) shellRoot.settingsTab = "appearance";
                                    else if (q.includes("lang") || q.includes("bahasa") || q.includes("prof") || q.includes("nama") || q.includes("avatar") || q.includes("foto")) shellRoot.settingsTab = "language_profile";
                                    else if (q.includes("bat") || q.includes("power") || q.includes("daya") || q.includes("lock") || q.includes("stor") || q.includes("disk") || q.includes("health") || q.includes("screen")) shellRoot.settingsTab = "power";
                                    else if (q.includes("key") || q.includes("touch") || q.includes("input") || q.includes("pintasan") || q.includes("scroll") || q.includes("niri")) shellRoot.settingsTab = "input_shortcuts";
                                    else if (q.includes("notif") || q.includes("island") || q.includes("banner") || q.includes("music")) shellRoot.settingsTab = "notifications_island";
                                }
                                Keys.onEscapePressed: shellRoot.closePopups()

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: LocaleStrings.searchPlaceholder
                                    color: ThemeTokens.textMuted
                                    font.pixelSize: 12
                                    visible: setSearchInput.text === ""
                                }
                            }

                            Text {
                                text: "✕"
                                color: ThemeTokens.textSecondary
                                font.pixelSize: 10
                                visible: setSearchInput.text !== ""
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: setSearchInput.text = ""
                                }
                            }
                        }
                    }

                    // Kartu Profil Akun Ringkas
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 10
                        color: profileM.containsMouse ? ThemeTokens.cardHoverBg : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 10

                            Rectangle {
                                width: 34; height: 34; radius: 17
                                color: ThemeTokens.accent
                                clip: true

                                Image {
                                    id: sideAvatarImg
                                    anchors.fill: parent
                                    source: ShellState.profileAvatar !== "" ? (ShellState.profileAvatar.startsWith("/") ? ("file://" + ShellState.profileAvatar) : ShellState.profileAvatar) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: ShellState.profileInitials
                                    color: ThemeTokens.textOnAccent
                                    font.pixelSize: 12
                                    font.bold: true
                                    visible: sideAvatarImg.status !== Image.Ready
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: ShellState.profileName
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: ShellState.osFullName + " • " + (shellRoot.sysSpecs.hostModel || "Workstation")
                                    color: ThemeTokens.textSecondary
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            id: profileM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.settingsTab = "language_profile"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: ThemeTokens.dividerColor
                    }

                    // Daftar Kategori Sidebar macOS
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Repeater {
                            model: [
                                { id: "appearance", title: LocaleStrings.navAppearance, badge: "#0A84FF", glyph: "◐" },
                                { id: "wallpaper", title: LocaleStrings.navWallpaper, badge: "#32ADE6", glyph: "▣" },
                                { id: "display_sound", title: LocaleStrings.navDisplaySound, badge: "#FF9F0A", glyph: "☀" },
                                { id: "input_shortcuts", title: LocaleStrings.t("Input & Pintasan", "Input & Shortcuts"), badge: "#64D2FF", glyph: "⌘" },
                                { id: "notifications_island", title: LocaleStrings.t("Notifikasi & Island", "Notifications & Island"), badge: "#FF375F", glyph: "◉" },
                                { id: "wifi", title: LocaleStrings.navWifi, badge: "#007AFF", glyph: "wifi" },
                                { id: "bluetooth", title: LocaleStrings.navBluetooth, badge: "#5E5CE6", glyph: "bt" },
                                { id: "power", title: LocaleStrings.navBatterySystem, badge: "#30D158", glyph: "⚡" },
                                { id: "language_profile", title: LocaleStrings.navLanguageProfile, badge: "#AF52DE", glyph: "☺" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 31
                                radius: 8
                                property bool active: shellRoot.settingsTab === modelData.id
                                color: active ? (settingsCard.activeNavPane === "right" ? Qt.rgba(ThemeTokens.accent.r, ThemeTokens.accent.g, ThemeTokens.accent.b, 0.55) : ThemeTokens.accent) : (navM.containsMouse ? ThemeTokens.cardHoverBg : "transparent")
                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 10
                                    spacing: 9

                                    Rectangle {
                                        width: 21; height: 21; radius: 6
                                        color: active ? "#33FFFFFF" : modelData.badge

                                        Canvas {
                                            anchors.centerIn: parent
                                            width: 14; height: 14
                                            visible: modelData.glyph === "wifi" || modelData.glyph === "bt"
                                            onPaint: {
                                                let ctx = getContext("2d"); ctx.reset();
                                                ctx.strokeStyle = "#FFFFFF"; ctx.fillStyle = "#FFFFFF";
                                                ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round";
                                                if (modelData.glyph === "wifi") {
                                                    for (let r = 2.5; r <= 7.5; r += 2.5) {
                                                        ctx.beginPath();
                                                        ctx.arc(7, 10.5, r, -Math.PI * 0.78, -Math.PI * 0.22);
                                                        ctx.stroke();
                                                    }
                                                    ctx.beginPath(); ctx.arc(7, 10.8, 1.1, 0, Math.PI * 2); ctx.fill();
                                                } else {
                                                    ctx.beginPath();
                                                    ctx.moveTo(4.5, 4.5); ctx.lineTo(9.5, 9.5); ctx.lineTo(7, 12);
                                                    ctx.moveTo(7, 2); ctx.lineTo(7, 12);
                                                    ctx.moveTo(7, 2); ctx.lineTo(9.5, 4.5); ctx.lineTo(4.5, 9.5);
                                                    ctx.stroke();
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: modelData.glyph !== "wifi" && modelData.glyph !== "bt"
                                            text: modelData.glyph
                                            color: "#FFFFFF"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        color: active ? ThemeTokens.textOnAccent : ThemeTokens.textPrimary
                                        font.pixelSize: 13
                                        font.weight: active ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: navM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.settingsTab = modelData.id
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Status Singkat di Bawah Sidebar
                    Text {
                        Layout.fillWidth: true
                        text: (ShellState.isSolid ? "Solid" : ("Liquid (" + ShellState.liquidVariant.toUpperCase() + ")")) + " • " + (ShellState.isDark ? "Dark" : "Light")
                        color: ThemeTokens.textMuted
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Garis Pemisah Vertikal Sidebar
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: ThemeTokens.dividerColor
            }

            // ── PANEL KANAN SCROLLABLE ───────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    flickDeceleration: 2000
                    maximumFlickVelocity: 2800
                    id: rightScroll
                    anchors.fill: parent
                    anchors.margins: 22
                    contentWidth: width
                    contentHeight: rightCol.implicitHeight + 16
                    clip: true
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    onMovementStarted: rightScrollAnim.stop()

                    WheelHandler {
                        id: rightWheelHandler
                        acceptedDevices: PointerDevice.AllDevices
                        onWheel: (ev) => {
                            ev.accepted = true;
                            let maxY = Math.max(0, rightScroll.contentHeight - rightScroll.height);
                            let step = ev.pixelDelta.y !== 0 ? -ev.pixelDelta.y * 1.15 : (-ev.angleDelta.y * 0.9);
                            let base = rightScrollAnim.running ? rightScrollAnim.to : rightScroll.contentY;
                            rightScrollAnim.stop();
                            rightScrollAnim.from = rightScroll.contentY;
                            rightScrollAnim.to = Math.max(0, Math.min(maxY, base + step));
                            rightScrollAnim.start();
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5
                    }

                    Rectangle {
                        id: rightFocusRing
                        parent: rightScroll.contentItem
                        z: 99
                        visible: false
                        property real targetX: 0
                        property real targetY: 0
                        property real targetW: 0
                        property real targetH: 0
                        property real targetR: 12
                        x: targetX
                        y: targetY
                        width: targetW
                        height: targetH
                        radius: targetR
                        color: Qt.rgba(ThemeTokens.accent.r, ThemeTokens.accent.g, ThemeTokens.accent.b, 0.10)
                        border.width: 2
                        border.color: ThemeTokens.accent
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }
                        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }
                        Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutExpo } }
                    }

                    ColumnLayout {
                        id: rightCol
                        property real tabGlideX: 0
                        property real tabZoom: 1.0
                        opacity: 1.0
                        scale: tabZoom
                        transformOrigin: Item.TopLeft
                        transform: Translate { x: rightCol.tabGlideX }



                        ParallelAnimation {
                            id: hyperTabAnim
                            NumberAnimation { target: rightCol; property: "opacity"; from: 0.0; to: 1.0; duration: 280; easing.type: Easing.OutExpo }
                            NumberAnimation { target: rightCol; property: "tabGlideX"; from: 18; to: 0; duration: 330; easing.type: Easing.OutExpo }
                            NumberAnimation { target: rightCol; property: "tabZoom"; from: 0.988; to: 1.0; duration: 330; easing.type: Easing.OutExpo }
                        }

                        Connections {
                            target: shellRoot
                            function onSettingsTabChanged() {
                                hyperTabAnim.restart();
                                Qt.callLater(settingsCard.refreshRightControls);
                            }
                        }
                        width: rightScroll.width
                        spacing: 16

                        // ====================================================
                        // KATEGORI 1: APPEARANCE (SOLID vs LIQUID + ISLAND + DOCK)
                        // ====================================================
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "appearance"

                            Text {
                                text: LocaleStrings.navAppearance
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }

                            // 1. Pilihan Utama Berdampingan: Solid vs Liquid
                            SettingsGroup {
                                Text {
                                    text: "Material Permukaan"
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Repeater {
                                        model: [
                                            { id: "solid", title: "Solid", sub: "Permukaan solid bersih hemat daya", icon: "■" },
                                            { id: "liquid", title: "Liquid", sub: "Efek kaca berlapis & refraksi", icon: "◈" }
                                        ]

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 68
                                            radius: 12
                                            property bool selected: ShellState.surfaceMode === modelData.id
                                            color: selected ? ThemeTokens.accentSoft : ThemeTokens.inputBg
                                            border.width: selected ? 1.8 : 1
                                            border.color: selected ? ThemeTokens.accent : ThemeTokens.borderSubtle

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 12
                                                spacing: 10

                                                Rectangle {
                                                    width: 36; height: 36; radius: 10
                                                    color: selected ? ThemeTokens.accent : ThemeTokens.cardBg
                                                    border.width: 1
                                                    border.color: selected ? ThemeTokens.accent : ThemeTokens.borderSubtle

                                                    Canvas {
                                                        anchors.centerIn: parent
                                                        width: 22; height: 22
                                                        property string modeId: modelData.id
                                                        property bool isSel: selected
                                                        property color fg: isSel ? "#FFFFFF" : ThemeTokens.textPrimary
                                                        onModeIdChanged: requestPaint()
                                                        onIsSelChanged: requestPaint()
                                                        onFgChanged: requestPaint()
                                                        onPaint: {
                                                            let ctx = getContext("2d");
                                                            ctx.reset();
                                                            ctx.save();
                                                            if (modeId === "solid") {
                                                                // Kotak Timbul (3D Embossed / Raised Box)
                                                                ctx.fillStyle = isSel ? "rgba(0,0,0,0.32)" : "rgba(0,0,0,0.22)";
                                                                ctx.beginPath();
                                                                ctx.roundedRect(5.5, 6.0, 13.5, 13.5, 3.2, 3.2);
                                                                ctx.fill();

                                                                ctx.fillStyle = fg;
                                                                ctx.beginPath();
                                                                ctx.roundedRect(3.5, 3.5, 13.5, 13.5, 3.2, 3.2);
                                                                ctx.fill();

                                                                // Highlight timbul tepi atas-kiri
                                                                ctx.strokeStyle = isSel ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.45)";
                                                                ctx.lineWidth = 1.2;
                                                                ctx.beginPath();
                                                                ctx.moveTo(5.0, 15.0);
                                                                ctx.lineTo(5.0, 5.2);
                                                                ctx.lineTo(15.2, 5.2);
                                                                ctx.stroke();
                                                            } else {
                                                                // Kotak Kaca Bergaris Miring (Diagonal Glass Reflections)
                                                                ctx.fillStyle = isSel ? "rgba(255,255,255,0.16)" : "rgba(128,140,160,0.14)";
                                                                ctx.strokeStyle = fg;
                                                                ctx.lineWidth = 1.45;
                                                                ctx.beginPath();
                                                                ctx.roundedRect(3.5, 3.5, 15.0, 15.0, 3.6, 3.6);
                                                                ctx.fill();
                                                                ctx.stroke();

                                                                // Clip ke dalam kotak kaca lalu gambar 2 garis kilau miring
                                                                ctx.beginPath();
                                                                ctx.roundedRect(4.2, 4.2, 13.6, 13.6, 3.0, 3.0);
                                                                ctx.clip();

                                                                ctx.strokeStyle = fg;
                                                                ctx.lineWidth = 2.0;
                                                                ctx.beginPath();
                                                                ctx.moveTo(4.0, 14.5);
                                                                ctx.lineTo(14.5, 4.0);
                                                                ctx.stroke();

                                                                ctx.lineWidth = 1.15;
                                                                ctx.globalAlpha = 0.72;
                                                                ctx.beginPath();
                                                                ctx.moveTo(8.5, 17.5);
                                                                ctx.lineTo(17.5, 8.5);
                                                                ctx.stroke();
                                                            }
                                                            ctx.restore();
                                                        }
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2
                                                    Text {
                                                        text: modelData.title
                                                        color: ThemeTokens.textPrimary
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                    }
                                                    Text {
                                                        text: modelData.sub
                                                        color: ThemeTokens.textSecondary
                                                        font.pixelSize: 10
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ShellState.setSurfaceMode(modelData.id);
                                                    hostWin.saveLayout();
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── TEMA WARNA SISTEM (BERLAKU GLOBAL UNTUK SOLID & LIQUID) ──
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text { text: "Tema Warna Sistem"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.Medium }
                                            Text { text: "Diterapkan ke seluruh bar, dock, widget, dan popup"; color: ThemeTokens.textSecondary; font.pixelSize: 11 }
                                        }

                                        Row {
                                            spacing: 8
                                            Repeater {
                                                model: [
                                                    { id: "light", label: "☀ Light" },
                                                    { id: "dark", label: "☾ Dark" }
                                                ]
                                                Rectangle {
                                                    width: 84; height: 32; radius: 8
                                                    property bool active: ShellState.colorScheme === modelData.id
                                                    color: active ? ThemeTokens.accent : ThemeTokens.inputBg
                                                    border.width: 1
                                                    border.color: active ? ThemeTokens.accent : ThemeTokens.borderSubtle
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: active ? ThemeTokens.textOnAccent : ThemeTokens.textPrimary
                                                        font.pixelSize: 12
                                                        font.weight: Font.DemiBold
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            ShellState.setColorScheme(modelData.id);
                                                            hostWin.saveLayout();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                    // Warna Aksen Dinamis (Standar vs Ekstrak Wallpaper)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text { text: "Warna Aksen Sistem"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.Medium }
                                            Text { text: "Sesuaikan aksen tombol & sorotan dengan wallpaper aktif"; color: ThemeTokens.textSecondary; font.pixelSize: 11 }
                                        }

                                        Row {
                                            spacing: 8
                                            Repeater {
                                                model: [
                                                    { adaptive: false, label: "Biru Standar" },
                                                    { adaptive: true,  label: "Ikuti Wallpaper" }
                                                ]
                                                Rectangle {
                                                    height: 32
                                                    width: accLbl.implicitWidth + 22
                                                    radius: 8
                                                    property bool active: ShellState.adaptiveAccent === modelData.adaptive
                                                    color: active ? ThemeTokens.accent : ThemeTokens.inputBg
                                                    border.width: 1
                                                    border.color: active ? ThemeTokens.accent : ThemeTokens.borderSubtle
                                                    Text {
                                                        id: accLbl
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: active ? "#FFFFFF" : ThemeTokens.textPrimary
                                                        font.pixelSize: 11
                                                        font.weight: Font.DemiBold
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            ShellState.adaptiveAccent = modelData.adaptive;
                                                            if (modelData.adaptive) shellRoot.extractWallpaperAccent();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── CABANG B: JIKA LIQUID DIPILIH -> 3 SUB-OPSI + DARK MODE TERPISAH ──
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    visible: ShellState.isLiquid

                                    Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Varian Liquid"
                                            color: ThemeTokens.textPrimary
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            height: 24
                                            width: resetGlassTxt.implicitWidth + 16
                                            radius: 7
                                            color: resetGlassM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.inputBg
                                            border.width: 1
                                            border.color: ThemeTokens.borderSubtle
                                            Text {
                                                id: resetGlassTxt
                                                anchors.centerIn: parent
                                                text: "Preset Bawaan"
                                                color: ThemeTokens.accent
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                            }
                                            MouseArea {
                                                id: resetGlassM
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ShellState.resetGlassPresets();
                                                    shellRoot.macOpacity = ShellState.macOpacity;
                                                    shellRoot.macFrost = ShellState.macFrost;
                                                    shellRoot.aeroBaseOpacity = ShellState.aeroBaseOpacity;
                                                    shellRoot.aeroSheenBright = ShellState.aeroSheenBright;
                                                    shellRoot.aeroSheenWidth = ShellState.aeroSheenWidth;
                                                    shellRoot.liquidOpacity = ShellState.liquidOpacity;
                                                    shellRoot.liquidRefraction = ShellState.liquidRefraction;
                                                    shellRoot.liquidFringing = ShellState.liquidFringing;
                                                    hostWin.saveLayout();
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Repeater {
                                            model: [
                                                { id: "mac", title: "Clean Glass", sub: "Frost halus" },
                                                { id: "aero", title: "Aero Blin", sub: "Kilau diagonal" },
                                                { id: "liquid", title: "Liquid Glass", sub: "Refraksi Niri" }
                                            ]

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 52
                                                radius: 10
                                                property bool active: ShellState.liquidVariant === modelData.id
                                                color: active ? ThemeTokens.accent : ThemeTokens.inputBg
                                                border.width: 1
                                                border.color: active ? ThemeTokens.accent : ThemeTokens.borderSubtle

                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 1
                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.title
                                                        color: active ? ThemeTokens.textOnAccent : ThemeTokens.textPrimary
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }
                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: modelData.sub
                                                        color: active ? "#E5F2FF" : ThemeTokens.textSecondary
                                                        font.pixelSize: 10
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        ShellState.setLiquidVariant(modelData.id);
                                                        hostWin.saveLayout();
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Parameter Kondisional Sesuai Varian Liquid Aktif
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: ShellState.liquidVariant === "mac"

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Transparansi"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 110 }
                                            MacSlider {
                                                Layout.fillWidth: true
                                                value: 1.0 - shellRoot.macOpacity
                                                minVal: 0.12; maxVal: 0.90
                                                onMoved: (v) => { shellRoot.macOpacity = Number((1.0 - v).toFixed(2)); hostWin.saveLayout(); }
                                            }
                                            Text { text: Math.round((1.0 - shellRoot.macOpacity) * 100) + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 11; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Intensitas Frost"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 110 }
                                            MacSlider {
                                                Layout.fillWidth: true
                                                value: shellRoot.macFrost
                                                minVal: 0.0; maxVal: 1.0
                                                onMoved: (v) => { shellRoot.macFrost = Number(v.toFixed(2)); hostWin.saveLayout(); }
                                            }
                                            Text { text: Math.round(shellRoot.macFrost * 100) + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 11; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: ShellState.liquidVariant === "aero"

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Transparansi"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 110 }
                                            MacSlider {
                                                Layout.fillWidth: true
                                                value: 1.0 - shellRoot.aeroBaseOpacity
                                                minVal: 0.12; maxVal: 0.90
                                                onMoved: (v) => { shellRoot.aeroBaseOpacity = Number((1.0 - v).toFixed(2)); hostWin.saveLayout(); }
                                            }
                                            Text { text: Math.round((1.0 - shellRoot.aeroBaseOpacity) * 100) + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 11; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Kecerahan Kilau"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 110 }
                                            MacSlider {
                                                Layout.fillWidth: true
                                                value: shellRoot.aeroSheenBright
                                                minVal: 0.0; maxVal: 1.0
                                                onMoved: (v) => { shellRoot.aeroSheenBright = Number(v.toFixed(2)); hostWin.saveLayout(); }
                                            }
                                            Text { text: Math.round(shellRoot.aeroSheenBright * 100) + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 11; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Lebar Garis Kilau"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 110 }
                                            MacSlider {
                                                Layout.fillWidth: true
                                                value: shellRoot.aeroSheenWidth
                                                minVal: 0.08; maxVal: 1.0
                                                onMoved: (v) => { shellRoot.aeroSheenWidth = Number(v.toFixed(2)); hostWin.saveLayout(); }
                                            }
                                            Text { text: Math.round(shellRoot.aeroSheenWidth * 100) + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 11; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: ShellState.liquidVariant === "liquid"

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Transparansi"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 110 }
                                            MacSlider {
                                                Layout.fillWidth: true
                                                value: 1.0 - shellRoot.liquidOpacity
                                                minVal: 0.12; maxVal: 0.90
                                                onMoved: (v) => { shellRoot.liquidOpacity = Number((1.0 - v).toFixed(2)); hostWin.saveLayout(); }
                                            }
                                            Text { text: Math.round((1.0 - shellRoot.liquidOpacity) * 100) + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 11; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Refraksi Tepi"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 110 }
                                            MacSlider {
                                                Layout.fillWidth: true
                                                value: shellRoot.liquidRefraction
                                                minVal: 0.0; maxVal: 1.0
                                                onMoved: (v) => { shellRoot.liquidRefraction = Number(v.toFixed(2)); hostWin.saveLayout(); }
                                            }
                                            Text { text: Math.round(shellRoot.liquidRefraction * 100) + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 11; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Dispersi Warna"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 110 }
                                            MacSlider {
                                                Layout.fillWidth: true
                                                value: shellRoot.liquidFringing
                                                minVal: 0.0; maxVal: 1.0
                                                onMoved: (v) => { shellRoot.liquidFringing = Number(v.toFixed(2)); hostWin.saveLayout(); }
                                            }
                                            Text { text: Math.round(shellRoot.liquidFringing * 100) + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 11; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                        }
                                    }
                                }
                            }

                            // 2. Perilaku Dock & Widget Desktop
                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Perilaku Dock"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                                    Row {
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { mode: "smart", label: "Smart" },
                                                { mode: "always", label: "Auto-Hide" },
                                                { mode: "never", label: "Selalu Tampil" }
                                            ]
                                            Rectangle {
                                                height: 28
                                                width: lblDock.implicitWidth + 18
                                                radius: 7
                                                property bool sel: shellRoot.dockHideMode === modelData.mode
                                                color: sel ? ThemeTokens.accent : ThemeTokens.inputBg
                                                Text {
                                                    id: lblDock
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: sel ? ThemeTokens.textOnAccent : ThemeTokens.textPrimary
                                                    font.pixelSize: 11
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        shellRoot.dockHideMode = modelData.mode;
                                                        hostWin.saveLayout();
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: "Kustomisasi Widget Desktop"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Atur posisi dan ukuran widget di layar utama"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    Rectangle {
                                        height: 30; width: 108; radius: 8
                                        color: ThemeTokens.inputBg
                                        border.width: 1; border.color: ThemeTokens.borderSubtle
                                        Text { anchors.centerIn: parent; text: "Edit Widget"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.weight: Font.Medium }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                shellRoot.closePopups();
                                                hostWin.editMode = true;
                                            }
                                        }
                                    }
                                }
                            }
                        
                            // Opsi Terpisah Dynamic Island: Melayang vs Menyatu
                            SettingsGroup {
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: LocaleStrings.secIslandLayout
                                        color: ThemeTokens.textPrimary
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: LocaleStrings.secIslandLayoutDesc
                                        color: ThemeTokens.textSecondary
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Repeater {
                                        model: [
                                            { id: "floating", title: LocaleStrings.optIslandFloating, sub: LocaleStrings.optIslandFloatingDesc, glyph: "▭" },
                                            { id: "merged", title: LocaleStrings.optIslandMerged, sub: LocaleStrings.optIslandMergedDesc, glyph: "▀" }
                                        ]

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 66
                                            radius: 12
                                            property bool selected: ShellState.islandLayoutMode === modelData.id
                                            color: selected ? ThemeTokens.accentSoft : ThemeTokens.inputBg
                                            border.width: selected ? 1.8 : 1
                                            border.color: selected ? ThemeTokens.accent : ThemeTokens.borderSubtle

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 12
                                                spacing: 10

                                                Rectangle {
                                                    width: 36; height: 36; radius: 10
                                                    color: selected ? ThemeTokens.accent : ThemeTokens.cardHoverBg
                                                    border.width: 1
                                                    border.color: selected ? ThemeTokens.accent : ThemeTokens.borderSubtle

                                                    Canvas {
                                                        anchors.centerIn: parent
                                                        width: 24; height: 22
                                                        property string islId: modelData.id
                                                        property bool isSel: selected
                                                        property color fg: isSel ? "#FFFFFF" : ThemeTokens.textPrimary
                                                        onIslIdChanged: requestPaint()
                                                        onIsSelChanged: requestPaint()
                                                        onFgChanged: requestPaint()
                                                        onPaint: {
                                                            let ctx = getContext("2d");
                                                            ctx.reset();
                                                            ctx.save();

                                                            // Bingkai layar mini
                                                            ctx.strokeStyle = fg;
                                                            ctx.globalAlpha = 0.42;
                                                            ctx.lineWidth = 1.15;
                                                            ctx.beginPath();
                                                            ctx.roundedRect(1.5, 2.5, 21.0, 17.0, 4.0, 4.0);
                                                            ctx.stroke();
                                                            ctx.globalAlpha = 1.0;

                                                            if (islId === "floating") {
                                                                // Mode Melayang: Logo Kapsul / Pil mengambang di tengah atas
                                                                ctx.fillStyle = fg;
                                                                ctx.beginPath();
                                                                ctx.roundedRect(6.0, 6.2, 12.0, 4.4, 2.2, 2.2);
                                                                ctx.fill();
                                                            } else {
                                                                // Mode Menyatu: Siluet Notch dengan lengkungan cekung menempel di tepi atas
                                                                ctx.fillStyle = fg;
                                                                ctx.beginPath();
                                                                ctx.moveTo(4.0, 2.8);
                                                                ctx.quadraticCurveTo(6.4, 2.8, 6.8, 5.2);
                                                                ctx.quadraticCurveTo(7.2, 7.6, 9.4, 7.6);
                                                                ctx.lineTo(14.6, 7.6);
                                                                ctx.quadraticCurveTo(16.8, 7.6, 17.2, 5.2);
                                                                ctx.quadraticCurveTo(17.6, 2.8, 20.0, 2.8);
                                                                ctx.closePath();
                                                                ctx.fill();
                                                            }
                                                            ctx.restore();
                                                        }
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2
                                                    Text {
                                                        text: modelData.title
                                                        color: ThemeTokens.textPrimary
                                                        font.pixelSize: 13
                                                        font.weight: Font.DemiBold
                                                    }
                                                    Text {
                                                        text: modelData.sub
                                                        color: ThemeTokens.textSecondary
                                                        font.pixelSize: 10
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ShellState.setIslandLayoutMode(modelData.id);
                                                    ShellState.saveProfile(ShellState.profileName, ShellState.profileAvatar);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                        }

                        // ====================================================
                        // KATEGORI 2: WALLPAPER (EKSPAINSI KONDISIONAL)
                        // ====================================================
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "wallpaper"

                            Text {
                                text: "Wallpaper"
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 14

                                    // Preview Wallpaper Aktif
                                    Rectangle {
                                        width: 184; height: 106; radius: 10
                                        color: ThemeTokens.inputBg
                                        border.width: 1; border.color: ThemeTokens.borderSubtle
                                        clip: true
                                        Image {
                                            anchors.fill: parent
                                            source: { let w = String(shellRoot.currentWallpaper || ""); if (!w) return ""; if (w.startsWith("file://") || w.startsWith("http://") || w.startsWith("https://")) return w; return "file://" + w; }
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize: Qt.size(368, 212)
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: String(shellRoot.currentWallpaper).split("/").pop() || "Wallpaper Aktif"
                                            color: ThemeTokens.textPrimary
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        RowLayout {
                                            spacing: 8
                                            Rectangle {
                                                height: 30; width: 104; radius: 8
                                                color: ThemeTokens.accent
                                                Text { anchors.centerIn: parent; text: "Ganti Acak"; color: ThemeTokens.textOnAccent; font.pixelSize: 11; font.bold: true }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.cycleWallpaper() }
                                            }
                                            Rectangle {
                                                height: 30; width: 88; radius: 8
                                                color: ThemeTokens.inputBg
                                                border.width: 1; border.color: ThemeTokens.borderSubtle
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: shellRoot.isFavoriteWallpaper(shellRoot.currentWallpaper) ? "★ Favorit" : "☆ Favorit"
                                                    color: ThemeTokens.textPrimary
                                                    font.pixelSize: 11
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: { shellRoot.toggleFavoriteWallpaper(shellRoot.currentWallpaper); hostWin.saveLayout(); }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            spacing: 8
                                            Rectangle {
                                                height: 28; width: 92; radius: 7
                                                color: ThemeTokens.inputBg
                                                border.width: 1; border.color: ThemeTokens.borderSubtle
                                                Text { anchors.centerIn: parent; text: "Buka Folder"; color: ThemeTokens.textPrimary; font.pixelSize: 11 }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.openWallpaperFolder() }
                                            }
                                            Rectangle {
                                                height: 28; width: 112; radius: 7
                                                color: settingsScope.showWallpaperAdvanced ? ThemeTokens.accentSoft : ThemeTokens.inputBg
                                                border.width: 1; border.color: settingsScope.showWallpaperAdvanced ? ThemeTokens.accent : ThemeTokens.borderSubtle
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: settingsScope.showWallpaperAdvanced ? "Sembunyikan Opsi" : "Opsi Lanjutan"
                                                    color: ThemeTokens.textPrimary
                                                    font.pixelSize: 11
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: settingsScope.showWallpaperAdvanced = !settingsScope.showWallpaperAdvanced
                                                }
                                            }
                                        }
                                    }
                                }

                                // Opsi Lanjutan Wallpaper (Hanya muncul saat dibuka)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    visible: settingsScope.showWallpaperAdvanced

                                    Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Sumber Wallpaper"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                                        Row {
                                            spacing: 6
                                            Repeater {
                                                model: [
                                                    { id: "sample", label: "Koleksi Folder" },
                                                    { id: "custom", label: "Custom Path" }
                                                ]
                                                Rectangle {
                                                    height: 28; width: 96; radius: 7
                                                    property bool sel: shellRoot.wallpaperSourceMode === modelData.id
                                                    color: sel ? ThemeTokens.accent : ThemeTokens.inputBg
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: sel ? ThemeTokens.textOnAccent : ThemeTokens.textPrimary
                                                        font.pixelSize: 11
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: { shellRoot.wallpaperSourceMode = modelData.id; shellRoot.reloadWallpapers(); hostWin.saveLayout(); }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Input Path Custom (Hanya muncul saat Custom Path dipilih)
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: shellRoot.wallpaperSourceMode === "custom"

                                        Rectangle {
                                            Layout.fillWidth: true; height: 32; radius: 8
                                            color: ThemeTokens.inputBg; border.width: 1; border.color: ThemeTokens.borderSubtle
                                            TextInput {
                                                id: customDirInput
                                                anchors.fill: parent; anchors.margins: 8
                                                verticalAlignment: Text.AlignVCenter
                                                color: ThemeTokens.textPrimary; font.pixelSize: 11; clip: true
                                                text: shellRoot.customWallpaperDir
                                                onTextEdited: shellRoot.customWallpaperDir = text
                                                onEditingFinished: { shellRoot.reloadWallpapers(); hostWin.saveLayout(); }
                                                Text {
                                                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                                    text: "Path folder wallpaper kustom..."
                                                    color: ThemeTokens.textMuted; font.pixelSize: 11
                                                    visible: customDirInput.text === ""
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true; height: 32; radius: 8
                                            color: ThemeTokens.inputBg; border.width: 1; border.color: ThemeTokens.borderSubtle
                                            TextInput {
                                                id: customFileInput
                                                anchors.fill: parent; anchors.margins: 8
                                                verticalAlignment: Text.AlignVCenter
                                                color: ThemeTokens.textPrimary; font.pixelSize: 11; clip: true
                                                text: shellRoot.customWallpaperFile
                                                onEditingFinished: {
                                                    shellRoot.customWallpaperFile = text;
                                                    let p = text.trim();
                                                    if (p !== "") {
                                                        shellRoot.wallpaperSourceMode = "custom";
                                                        shellRoot.currentWallpaper = p.startsWith("file://") ? p : "file://" + p;
                                                    }
                                                    hostWin.saveLayout();
                                                }
                                                Text {
                                                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                                    text: "Path file gambar/video spesifik..."
                                                    color: ThemeTokens.textMuted; font.pixelSize: 11
                                                    visible: customFileInput.text === ""
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Rotasi Otomatis (Menit, 0 = Mati)"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.fillWidth: true }

                                        Row {
                                            spacing: 6
                                            Rectangle {
                                                width: 28; height: 28; radius: 7; color: ThemeTokens.inputBg
                                                Text { anchors.centerIn: parent; text: "−"; color: ThemeTokens.textPrimary; font.bold: true }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shellRoot.autoCycleMinutes = Math.max(0, shellRoot.autoCycleMinutes - 5); hostWin.saveLayout(); } }
                                            }
                                            Rectangle {
                                                width: 54; height: 28; radius: 7; color: ThemeTokens.inputBg; border.width: 1; border.color: ThemeTokens.borderSubtle
                                                TextInput {
                                                    id: customMinInput
                                                    anchors.fill: parent
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    color: ThemeTokens.textPrimary
                                                    font.pixelSize: 12
                                                    validator: IntValidator { bottom: 0; top: 1440 }
                                                    text: String(shellRoot.autoCycleMinutes)
                                                    onEditingFinished: {
                                                        let parsed = parseInt(text);
                                                        shellRoot.autoCycleMinutes = isNaN(parsed) ? 0 : Math.max(0, Math.min(1440, parsed));
                                                        text = Qt.binding(function() { return String(shellRoot.autoCycleMinutes); });
                                                        customMinInput.focus = false;
                                                        hostWin.saveLayout();
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                width: 28; height: 28; radius: 7; color: ThemeTokens.inputBg
                                                Text { anchors.centerIn: parent; text: "+"; color: ThemeTokens.textPrimary; font.bold: true }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shellRoot.autoCycleMinutes = Math.min(1440, shellRoot.autoCycleMinutes + 5); hostWin.saveLayout(); } }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Live / Video Wallpaper"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                                        MacSwitch {
                                            checked: shellRoot.liveWallpaperEnabled
                                            onToggled: { shellRoot.liveWallpaperEnabled = !shellRoot.liveWallpaperEnabled; shellRoot.reloadWallpapers(); hostWin.saveLayout(); }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: shellRoot.liveWallpaperEnabled
                                        Text { text: "Jeda Otomatis Saat Tertutup Jendela"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.fillWidth: true }
                                        MacSwitch {
                                            checked: shellRoot.pauseWhenUnseen
                                            onToggled: { shellRoot.pauseWhenUnseen = !shellRoot.pauseWhenUnseen; hostWin.saveLayout(); }
                                        }
                                    }
                                }
                            }

                            // Koleksi Wallpaper Tanpa Nested Scroll
                            Text {
                                text: "Koleksi (" + shellRoot.wallpaperList.length + ")"
                                color: ThemeTokens.textSecondary
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            GridView {
        populate: Transition { NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }
        flickDeceleration: 2400
        maximumFlickVelocity: 2800
                                id: wallCollectionGrid
                                Layout.fillWidth: true
                                Layout.preferredHeight: 276
                                cellWidth: Math.floor((width > 0 ? width : 520) / 3)
                                cellHeight: 92
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: shellRoot.wallpaperList

                                delegate: Item {
                                    width: wallCollectionGrid.cellWidth
                                    height: wallCollectionGrid.cellHeight

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        radius: 10
                                        color: ThemeTokens.inputBg
                                        border.width: shellRoot.currentWallpaper === modelData ? 2 : 1
                                        border.color: shellRoot.currentWallpaper === modelData ? ThemeTokens.accent : ThemeTokens.borderSubtle
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: {
                                                let w = String(modelData || "");
                                                if (!w) return "";
                                                return (w.startsWith("file://") || w.startsWith("http://") || w.startsWith("https://")) ? w : ("file://" + w);
                                            }
                                            sourceSize: Qt.size(220, 128)
                                            asynchronous: true
                                            cache: true
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                        }

                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.margins: 6
                                            width: 20; height: 20; radius: 10
                                            color: ThemeTokens.accent
                                            visible: shellRoot.currentWallpaper === modelData
                                            Text { anchors.centerIn: parent; text: "✓"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                shellRoot.currentWallpaper = modelData;
                                                hostWin.saveLayout();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ====================================================
                        // KATEGORI 3: DISPLAYS & SOUND
                        // ====================================================
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "display_sound"

                            Text {
                                text: "Displays & Sound"
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }

                            SettingsGroup {
                                Text { text: "Layar"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Kecerahan"; color: ThemeTokens.textSecondary; font.pixelSize: 12; Layout.preferredWidth: 96 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        value: shellRoot.brightnessLevel
                                        minVal: 5; maxVal: 100
                                        onMoved: (v) => shellRoot.setBrightnessPct(v)
                                    }
                                    Text { text: shellRoot.brightnessLevel + "%"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: shellRoot.sysSpecs.displayInfo || "Layar Utama"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: shellRoot.sysSpecs.gpuModel || ""; color: ThemeTokens.textSecondary; font.pixelSize: 11 }
                                }
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Audio"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                    Text { text: shellRoot.volumeMuted ? "Muted" : "Aktif"; color: ThemeTokens.textSecondary; font.pixelSize: 11 }
                                    MacSwitch {
                                        checked: !shellRoot.volumeMuted
                                        onToggled: shellRoot.toggleMute()
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Volume Utama"; color: ThemeTokens.textSecondary; font.pixelSize: 12; Layout.preferredWidth: 96 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        enabledControl: !shellRoot.volumeMuted
                                        value: shellRoot.volumeLevel
                                        minVal: 0; maxVal: 100
                                        onMoved: (v) => shellRoot.setVolumePct(v)
                                    }
                                    Text { text: shellRoot.volumeMuted ? "0%" : (shellRoot.volumeLevel + "%"); color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                }
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Do Not Disturb"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text { text: "Heningkan notifikasi saat fokus"; color: ThemeTokens.textSecondary; font.pixelSize: 11 }
                                    }
                                    MacSwitch {
                                        checked: shellRoot.dndEnabled
                                        onToggled: shellRoot.toggleDnd()
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Cegah Layar Tidur (Keep Awake)"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text { text: "Tahan idle & sleep sistem"; color: ThemeTokens.textSecondary; font.pixelSize: 11 }
                                    }
                                    MacSwitch {
                                        checked: shellRoot.keepAwake
                                        onToggled: shellRoot.toggleKeepAwake()
                                    }
                                }
                            }
                        }

                        // ====================================================
                        // KATEGORI 4: WI-FI (EKSPAINSI KONDISIONAL SAAT ON)
                        // ====================================================
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "wifi"

                            Text {
                                text: "Wi-Fi"
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Wi-Fi"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text {
                                            text: shellRoot.wifiEnabled ? (shellRoot.wifiName + " • IP " + shellRoot.localIpAddr) : "Wi-Fi Nonaktif"
                                            color: ThemeTokens.textSecondary
                                            font.pixelSize: 11
                                        }
                                    }

                                    Rectangle {
                                        height: 28; width: 74; radius: 7
                                        color: ThemeTokens.inputBg
                                        border.width: 1; border.color: ThemeTokens.borderSubtle
                                        visible: shellRoot.wifiEnabled
                                        Text { anchors.centerIn: parent; text: shellRoot.wifiScanning ? "Memindai..." : "Pindai"; color: ThemeTokens.textPrimary; font.pixelSize: 11 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.scanWifiNetworks() }
                                    }

                                    MacSwitch {
                                        checked: shellRoot.wifiEnabled
                                        onToggled: shellRoot.toggleWifi()
                                    }
                                }
                            }

                            // Input Sandi Kondisional
                            SettingsGroup {
                                visible: shellRoot.wifiEnabled && shellRoot.wifiPasswordTarget !== ""
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    TextInput {
                                        id: setWifiPassField
                                        Layout.fillWidth: true
                                        echoMode: TextInput.Password
                                        color: ThemeTokens.textPrimary
                                        font.pixelSize: 12
                                        onAccepted: shellRoot.connectWifi(shellRoot.wifiPasswordTarget, text)
                                        Text {
                                            anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                            text: "Kata sandi untuk " + shellRoot.wifiPasswordTarget + "..."
                                            color: ThemeTokens.textMuted; font.pixelSize: 11
                                            visible: setWifiPassField.text === ""
                                        }
                                    }
                                    Rectangle {
                                        height: 28; width: 88; radius: 7
                                        color: ThemeTokens.accent
                                        Text { anchors.centerIn: parent; text: "Hubungkan"; color: ThemeTokens.textOnAccent; font.pixelSize: 11; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.connectWifi(shellRoot.wifiPasswordTarget, setWifiPassField.text) }
                                    }
                                }
                            }

                            // Daftar Jaringan (Hilang otomatis saat Wi-Fi OFF)
                            SettingsGroup {
                                visible: shellRoot.wifiEnabled

                                Text {
                                    text: "Jaringan Tersedia"
                                    color: ThemeTokens.textSecondary
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Repeater {
                                    model: shellRoot.wifiNetworks
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 38
                                        radius: 8
                                        color: modelData.connected ? ThemeTokens.accentSoft : (wRowM.containsMouse ? ThemeTokens.cardHoverBg : "transparent")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 10

                                            Text {
                                                text: modelData.connected ? "✓" : "ᯤ"
                                                color: modelData.connected ? ThemeTokens.accent : ThemeTokens.textSecondary
                                                font.pixelSize: 12
                                                font.bold: true
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.ssid
                                                color: ThemeTokens.textPrimary
                                                font.pixelSize: 12
                                                font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: (modelData.secured ? "🔒 " : "") + modelData.signal + "%"
                                                color: ThemeTokens.textSecondary
                                                font.pixelSize: 11
                                            }
                                        }

                                        MouseArea {
                                            id: wRowM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.connected) return;
                                                if (modelData.secured) {
                                                    shellRoot.wifiStatusMsg = "";
                                                    shellRoot.wifiPasswordTarget = modelData.ssid;
                                                    setWifiPassField.text = "";
                                                    setWifiPassField.forceActiveFocus();
                                                } else {
                                                    shellRoot.wifiPasswordTarget = "";
                                                    shellRoot.connectWifi(modelData.ssid, "");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ====================================================
                        // KATEGORI 5: BLUETOOTH (EKSPAINSI KONDISIONAL SAAT ON)
                        // ====================================================
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "bluetooth"

                            Text {
                                text: "Bluetooth"
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Bluetooth"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text {
                                            text: shellRoot.btEnabled ? (shellRoot.btDeviceName !== "" ? "Terhubung: " + shellRoot.btDeviceName : "Dapat ditemukan") : "Bluetooth Nonaktif"
                                            color: ThemeTokens.textSecondary
                                            font.pixelSize: 11
                                        }
                                    }

                                    Rectangle {
                                        height: 28; width: 74; radius: 7
                                        color: ThemeTokens.inputBg
                                        border.width: 1; border.color: ThemeTokens.borderSubtle
                                        visible: shellRoot.btEnabled
                                        Text { anchors.centerIn: parent; text: shellRoot.btScanning ? "Memindai..." : "Pindai"; color: ThemeTokens.textPrimary; font.pixelSize: 11 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.scanBtDevices() }
                                    }

                                    MacSwitch {
                                        checked: shellRoot.btEnabled
                                        onToggled: shellRoot.toggleBluetooth()
                                    }
                                }
                            }

                            SettingsGroup {
                                visible: shellRoot.btEnabled

                                Text {
                                    text: "Perangkat"
                                    color: ThemeTokens.textSecondary
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Repeater {
                                    model: shellRoot.btDevices
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 38
                                        radius: 8
                                        color: modelData.connected ? ThemeTokens.accentSoft : (btRowM.containsMouse ? ThemeTokens.cardHoverBg : "transparent")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 10

                                            Text {
                                                text: modelData.connected ? "✓" : "ᛒ"
                                                color: modelData.connected ? ThemeTokens.accent : ThemeTokens.textSecondary
                                                font.pixelSize: 12
                                                font.bold: true
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                color: ThemeTokens.textPrimary
                                                font.pixelSize: 12
                                                font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: shellRoot.btBusyMac === modelData.mac ? "Proses..." : (modelData.connected ? "Terhubung" : "Hubungkan")
                                                color: modelData.connected ? ThemeTokens.success : ThemeTokens.textSecondary
                                                font.pixelSize: 11
                                            }
                                        }

                                        MouseArea {
                                            id: btRowM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: shellRoot.toggleBtDevice(modelData.mac, modelData.connected)
                                        }
                                    }
                                }
                            }
                        }

                        // ====================================================
                        // KATEGORI 6: BATTERY & SYSTEM
                        // ====================================================
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "input_shortcuts"

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: LocaleStrings.t("Input & Pintasan", "Input & Shortcuts")
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 18
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: settingsScope.niriInputFeedback
                                    color: ThemeTokens.success
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    opacity: settingsScope.niriInputFeedback !== "" ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                }
                            }

                            SettingsGroup {
                                Text { text: "Touchpad (Trackpad)"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Ketuk untuk Klik (Tap to Click)"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Ketuk ringan pada permukaan touchpad sebagai klik kiri"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.tpTapToClick
                                        onToggled: { settingsScope.tpTapToClick = !settingsScope.tpTapToClick; settingsScope.applyNiriInputConfig(); }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Natural Scroll (Gulir Alami)"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Konten layar bergerak searah dengan gerakan jari"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.tpNaturalScroll
                                        onToggled: { settingsScope.tpNaturalScroll = !settingsScope.tpNaturalScroll; settingsScope.applyNiriInputConfig(); }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Nonaktifkan Touchpad Saat Mengetik"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Mencegah kursor melompat akibat telapak tangan menyentuh touchpad"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.tpDisableWhileTyping
                                        onToggled: { settingsScope.tpDisableWhileTyping = !settingsScope.tpDisableWhileTyping; settingsScope.applyNiriInputConfig(); }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Mode Tangan Kiri Touchpad"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Menukar tombol klik utama touchpad untuk pengguna kidal"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.tpLeftHanded
                                        onToggled: { settingsScope.tpLeftHanded = !settingsScope.tpLeftHanded; settingsScope.applyNiriInputConfig(); }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Kecepatan Pointer"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 140 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        value: settingsScope.tpAccelSpeed
                                        minVal: -0.8; maxVal: 1.0
                                        onMoved: (v) => { settingsScope.tpAccelSpeed = Number(v.toFixed(2)); settingsScope.applyNiriInputConfig(); }
                                    }
                                    Text { text: (settingsScope.tpAccelSpeed >= 0 ? "+" : "") + settingsScope.tpAccelSpeed.toFixed(2); color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Kecepatan Gulir"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 140 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        value: settingsScope.tpScrollFactor
                                        minVal: 0.3; maxVal: 2.5
                                        onMoved: (v) => { settingsScope.tpScrollFactor = Number(v.toFixed(2)); settingsScope.applyNiriInputConfig(); }
                                    }
                                    Text { text: settingsScope.tpScrollFactor.toFixed(1) + "x"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Profil Akselerasi"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                                    Row {
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { id: "adaptive", label: "Adaptive" },
                                                { id: "flat", label: "Flat" }
                                            ]
                                            Rectangle {
                                                height: 26; width: 76; radius: 7
                                                property bool sel: settingsScope.tpAccelProfile === modelData.id
                                                color: sel ? ThemeTokens.accent : ThemeTokens.inputBg
                                                Text { anchors.centerIn: parent; text: modelData.label; color: sel ? "#FFFFFF" : ThemeTokens.textPrimary; font.pixelSize: 11; font.weight: Font.DemiBold }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { settingsScope.tpAccelProfile = modelData.id; settingsScope.applyNiriInputConfig(); } }
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                Text { text: "Mouse Eksternal"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Kecepatan Pointer Mouse"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 150 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        value: settingsScope.msAccelSpeed
                                        minVal: -0.8; maxVal: 1.0
                                        onMoved: (v) => { settingsScope.msAccelSpeed = Number(v.toFixed(2)); settingsScope.applyNiriInputConfig(); }
                                    }
                                    Text { text: (settingsScope.msAccelSpeed >= 0 ? "+" : "") + settingsScope.msAccelSpeed.toFixed(2); color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Kecepatan Roda Gulir"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 150 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        value: settingsScope.msScrollFactor
                                        minVal: 0.3; maxVal: 2.5
                                        onMoved: (v) => { settingsScope.msScrollFactor = Number(v.toFixed(2)); settingsScope.applyNiriInputConfig(); }
                                    }
                                    Text { text: settingsScope.msScrollFactor.toFixed(1) + "x"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Profil Akselerasi Mouse"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Flat untuk presisi 1:1 (gaming/desain), Adaptive untuk harian"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    Row {
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { id: "flat", label: "Flat" },
                                                { id: "adaptive", label: "Adaptive" }
                                            ]
                                            Rectangle {
                                                height: 26; width: 76; radius: 7
                                                property bool sel: settingsScope.msAccelProfile === modelData.id
                                                color: sel ? ThemeTokens.accent : ThemeTokens.inputBg
                                                Text { anchors.centerIn: parent; text: modelData.label; color: sel ? "#FFFFFF" : ThemeTokens.textPrimary; font.pixelSize: 11; font.weight: Font.DemiBold }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { settingsScope.msAccelProfile = modelData.id; settingsScope.applyNiriInputConfig(); } }
                                            }
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Natural Scroll Mouse"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Balikkan arah gulir roda mouse mengikuti arah jari"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.msNaturalScroll
                                        onToggled: { settingsScope.msNaturalScroll = !settingsScope.msNaturalScroll; settingsScope.applyNiriInputConfig(); }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Mode Tangan Kiri (Tukar Klik Kiri & Kanan)"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Ubah tombol utama mouse menjadi tombol kanan"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.msLeftHanded
                                        onToggled: { settingsScope.msLeftHanded = !settingsScope.msLeftHanded; settingsScope.applyNiriInputConfig(); }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Emulasi Klik Tengah (Klik Kiri + Kanan)"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Tekan klik kiri & kanan bersamaan untuk menempel teks atau buka tab baru"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.msMiddleEmulation
                                        onToggled: { settingsScope.msMiddleEmulation = !settingsScope.msMiddleEmulation; settingsScope.applyNiriInputConfig(); }
                                    }
                                }
                            }

                            SettingsGroup {
                                Text { text: "Perilaku Fokus & Multitasking Jendela"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Fokus Mengikuti Kursor (Focus Follows Mouse)"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Otomatis mengaktifkan jendela saat kursor diarahkan ke atasnya"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.niriFocusFollowsMouse
                                        onToggled: { settingsScope.niriFocusFollowsMouse = !settingsScope.niriFocusFollowsMouse; settingsScope.applyNiriInputConfig(); }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Kursor Mengikuti Fokus Jendela (Warp Mouse)"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Pindahkan kursor otomatis ke tengah jendela yang baru difokuskan"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: settingsScope.niriWarpMouseToFocus
                                        onToggled: { settingsScope.niriWarpMouseToFocus = !settingsScope.niriWarpMouseToFocus; settingsScope.applyNiriInputConfig(); }
                                    }
                                }
                            }

                            SettingsGroup {
                                Text { text: "Keyboard & Respons Tombol"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Repeat Delay"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 130 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        value: settingsScope.kbRepeatDelay
                                        minVal: 150; maxVal: 800
                                        onMoved: (v) => { settingsScope.kbRepeatDelay = Math.round(v); settingsScope.applyNiriInputConfig(); }
                                    }
                                    Text { text: settingsScope.kbRepeatDelay + " ms"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 50; horizontalAlignment: Text.AlignRight }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Repeat Rate"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 130 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        value: settingsScope.kbRepeatRate
                                        minVal: 15; maxVal: 60
                                        onMoved: (v) => { settingsScope.kbRepeatRate = Math.round(v); settingsScope.applyNiriInputConfig(); }
                                    }
                                    Text { text: settingsScope.kbRepeatRate + " /dtk"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 50; horizontalAlignment: Text.AlignRight }
                                }
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Pintasan Niri (~/.config/niri/config.kdl)"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { text: "Tambah pintasan cepat atau buka daftar lengkap"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    Rectangle {
                                        height: 28; width: 104; radius: 8; color: ThemeTokens.accent
                                        Text { anchors.centerIn: parent; text: "Semua (⌘/)"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.switchPopup("keybinds") }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Rectangle {
                                        Layout.preferredWidth: 130; height: 30; radius: 8
                                        color: ThemeTokens.inputBg; border.width: 1; border.color: ThemeTokens.borderSubtle
                                        TextInput {
                                            id: newBindKeyIn
                                            anchors.fill: parent; anchors.margins: 7
                                            verticalAlignment: Text.AlignVCenter; color: ThemeTokens.textPrimary; font.pixelSize: 11; clip: true
                                            text: settingsScope.newBindCombo
                                            onTextChanged: settingsScope.newBindCombo = text
                                            Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Contoh: Mod+B"; color: ThemeTokens.textMuted; font.pixelSize: 10; visible: newBindKeyIn.text === "" }
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 30; radius: 8
                                        color: ThemeTokens.inputBg; border.width: 1; border.color: ThemeTokens.borderSubtle
                                        TextInput {
                                            id: newBindCmdIn
                                            anchors.fill: parent; anchors.margins: 7
                                            verticalAlignment: Text.AlignVCenter; color: ThemeTokens.textPrimary; font.pixelSize: 11; clip: true
                                            text: settingsScope.newBindCmd
                                            onTextChanged: settingsScope.newBindCmd = text
                                            Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Perintah (contoh: firefox)"; color: ThemeTokens.textMuted; font.pixelSize: 10; visible: newBindCmdIn.text === "" }
                                        }
                                    }
                                    Rectangle {
                                        height: 30; width: 74; radius: 8; color: ThemeTokens.inputBg; border.width: 1; border.color: ThemeTokens.borderSubtle
                                        Text { anchors.centerIn: parent; text: "+ Tambah"; color: ThemeTokens.accent; font.pixelSize: 11; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsScope.addNiriCustomBind() }
                                    }
                                }

                                Repeater {
                                    model: settingsScope.niriBindsList.slice(0, 8)
                                    Rectangle {
                                        Layout.fillWidth: true; height: 28; radius: 7
                                        color: ThemeTokens.inputBg
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                            Text { text: modelData.combo; color: ThemeTokens.accent; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 145; elide: Text.ElideRight }
                                            Text { text: modelData.action; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "notifications_island"

                            Text {
                                text: LocaleStrings.t("Notifikasi & Dynamic Island", "Notifications & Dynamic Island")
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }

                            SettingsGroup {
                                Text { text: "Pratinjau & Perilaku Dynamic Island"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 64
                                    radius: 12
                                    color: ThemeTokens.inputBg

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: settingsScope.islandMode === "expanded" ? 260 : (settingsScope.islandMode === "compact" ? 136 : 196)
                                        height: 32
                                        radius: 16
                                        color: "#0A0A0E"
                                        border.width: 1
                                        border.color: "#2C2C34"
                                        opacity: settingsScope.islandEnabled ? 1.0 : 0.35
                                        Behavior on width { SpringAnimation { mass: 0.9; spring: 6.5; damping: 0.50; epsilon: 0.001 } }
                                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                                            Rectangle { width: 8; height: 8; radius: 4; color: ThemeTokens.accent }
                                            Text { text: "NivrOS Island"; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: settingsScope.islandMode.toUpperCase(); color: "#98989F"; font.pixelSize: 9; visible: settingsScope.islandMode !== "compact" }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Aktifkan Dynamic Island"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                                    MacSwitch {
                                        checked: settingsScope.islandEnabled
                                        onToggled: settingsScope.islandEnabled = !settingsScope.islandEnabled
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Preview Musik Saat Hover"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                                    MacSwitch {
                                        checked: settingsScope.islandMusicHover
                                        onToggled: settingsScope.islandMusicHover = !settingsScope.islandMusicHover
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Repeater {
                                        model: [
                                            { id: "compact", label: "Compact" },
                                            { id: "adaptive", label: "Adaptif" },
                                            { id: "expanded", label: "Selalu Luas" }
                                        ]
                                        Rectangle {
                                            Layout.fillWidth: true; height: 30; radius: 8
                                            property bool sel: settingsScope.islandMode === modelData.id
                                            color: sel ? ThemeTokens.accent : ThemeTokens.inputBg
                                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            Text { anchors.centerIn: parent; text: modelData.label; color: sel ? "#FFFFFF" : ThemeTokens.textPrimary; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsScope.islandMode = modelData.id }
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Banner & Fokus Notifikasi"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                    Rectangle {
                                        height: 26; width: 96; radius: 7; color: ThemeTokens.accentSoft; border.width: 1; border.color: ThemeTokens.accent
                                        Text { anchors.centerIn: parent; text: "Uji Notifikasi"; color: ThemeTokens.accent; font.pixelSize: 11; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                settingsScope.notifTestBanner = "Contoh notifikasi melayang NivrOS (" + settingsScope.notifDurationSec + " detik)";
                                                notifBannerClearTimer.restart();
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: settingsScope.notifTestBanner !== "" ? 38 : 0
                                    opacity: settingsScope.notifTestBanner !== "" ? 1.0 : 0.0
                                    radius: 9
                                    color: ThemeTokens.accentSoft
                                    border.width: 1; border.color: ThemeTokens.accent
                                    clip: true
                                    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: settingsScope.notifTestBanner
                                        color: ThemeTokens.textPrimary
                                        font.pixelSize: 11; font.weight: Font.DemiBold
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Durasi Tampil Banner"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.preferredWidth: 145 }
                                    MacSlider {
                                        Layout.fillWidth: true
                                        value: settingsScope.notifDurationSec
                                        minVal: 2; maxVal: 10
                                        onMoved: (v) => settingsScope.notifDurationSec = Math.round(v)
                                    }
                                    Text { text: settingsScope.notifDurationSec + " dtk"; color: ThemeTokens.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Mode Jangan Ganggu (Do Not Disturb)"; color: ThemeTokens.textPrimary; font.pixelSize: 12 }
                                        Text { text: "Senyapkan pop-up notifikasi saat presentasi atau fokus"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    MacSwitch {
                                        checked: shellRoot.dndEnabled
                                        onToggled: shellRoot.toggleDnd()
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "power"

                            Text {
                                text: "Battery & System"
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Low Power Mode"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { text: "Kurangi konsumsi daya & kecepatan kipas agar baterai lebih awet"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    Row {
                                        spacing: 5
                                        Repeater {
                                            model: [
                                                { id: "never", label: "Never", prof: "performance" },
                                                { id: "battery", label: "On Battery", prof: "balanced" },
                                                { id: "always", label: "Always", prof: "power-saver" }
                                            ]
                                            Rectangle {
                                                height: 26; width: 72; radius: 7
                                                property bool sel: settingsScope.lowPowerPolicy === modelData.id
                                                color: sel ? ThemeTokens.accent : ThemeTokens.inputBg
                                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                                Text { anchors.centerIn: parent; text: modelData.label; color: sel ? "#FFFFFF" : ThemeTokens.textPrimary; font.pixelSize: 10; font.weight: Font.DemiBold }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        settingsScope.lowPowerPolicy = modelData.id;
                                                        settingsScope.setPowerProfile(modelData.prof);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Battery Health"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text {
                                            text: "Kapasitas Maksimum: " + settingsScope.batHealthPct + "% • " + settingsScope.batTech + (settingsScope.batCycleCount > 0 ? (" • " + settingsScope.batCycleCount + " Siklus") : "")
                                            color: ThemeTokens.textSecondary; font.pixelSize: 10
                                        }
                                    }
                                    Rectangle {
                                        height: 26; width: 88; radius: 13
                                        color: settingsScope.batHealthPct >= 80 ? Qt.rgba(0.19, 0.82, 0.35, 0.16) : Qt.rgba(1.0, 0.62, 0.04, 0.18)
                                        Text {
                                            anchors.centerIn: parent
                                            text: settingsScope.batHealthPct >= 80 ? ("Normal • " + settingsScope.batHealthPct + "%") : ("Service • " + settingsScope.batHealthPct + "%")
                                            color: settingsScope.batHealthPct >= 80 ? "#30D158" : "#FF9F0A"
                                            font.pixelSize: 11; font.bold: true
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 1
                                        Text { text: "Battery Level & Screen Time"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { text: "Level: " + shellRoot.batteryPct + "% • " + settingsScope.screenOnSummary; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    Row {
                                        spacing: 4
                                        Repeater {
                                            model: [
                                                { id: "24h", label: "Last 24 Hours" },
                                                { id: "10d", label: "Last 10 Days" }
                                            ]
                                            Rectangle {
                                                height: 26; width: 92; radius: 7
                                                property bool sel: settingsScope.batChartRange === modelData.id
                                                color: sel ? ThemeTokens.accent : ThemeTokens.inputBg
                                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                                Text { anchors.centerIn: parent; text: modelData.label; color: sel ? "#FFFFFF" : ThemeTokens.textPrimary; font.pixelSize: 10; font.weight: Font.DemiBold }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsScope.batChartRange = modelData.id }
                                            }
                                        }
                                    }
                                }

                                Text { text: "Battery Level"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.weight: Font.DemiBold }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 82
                                    radius: 10
                                    color: ThemeTokens.inputBg

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: settingsScope.batChartRange === "24h" ? 4 : 10

                                        Repeater {
                                            model: settingsScope.batChartRange === "24h" ? settingsScope.batHistory24h : settingsScope.batHistory10d
                                            Item {
                                                width: Math.max(4, (parent.width - (settingsScope.batChartRange === "24h" ? 23 * 4 : 9 * 10)) / (settingsScope.batChartRange === "24h" ? 24 : 10))
                                                height: parent.height

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    height: Math.max(4, parent.height * (modelData / 100.0))
                                                    radius: 3
                                                    color: modelData <= 20 ? "#FF453A" : "#30D158"
                                                    Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutExpo } }
                                                }
                                            }
                                        }
                                    }
                                }

                                Text { text: "Screen On Usage"; color: ThemeTokens.textPrimary; font.pixelSize: 11; font.weight: Font.DemiBold }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 76
                                    radius: 10
                                    color: ThemeTokens.inputBg

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: settingsScope.batChartRange === "24h" ? 4 : 10

                                        Repeater {
                                            model: settingsScope.batChartRange === "24h" ? settingsScope.screenHistory24h : settingsScope.screenHistory10d
                                            Item {
                                                property real maxRef: settingsScope.batChartRange === "24h" ? 60.0 : 420.0
                                                width: Math.max(4, (parent.width - (settingsScope.batChartRange === "24h" ? 23 * 4 : 9 * 10)) / (settingsScope.batChartRange === "24h" ? 24 : 10))
                                                height: parent.height

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    height: Math.max(3, parent.height * Math.min(1.0, modelData / maxRef))
                                                    radius: 3
                                                    color: "#0A84FF"
                                                    Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutExpo } }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Storage"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                    Text {
                                        text: settingsScope.storageUsedGb.toFixed(1) + " GB digunakan dari " + settingsScope.storageTotalGb.toFixed(0) + " GB"
                                        color: ThemeTokens.textSecondary; font.pixelSize: 11
                                    }
                                }

                                Rectangle {
                                    id: storageTrack
                                    Layout.fillWidth: true
                                    height: 16
                                    radius: 8
                                    color: ThemeTokens.inputBg
                                    clip: true

                                    Row {
                                        anchors.fill: parent
                                        spacing: 2

                                        Rectangle {
                                            height: parent.height
                                            width: Math.max(6, storageTrack.width * (settingsScope.storageSysGb / Math.max(1, settingsScope.storageTotalGb)))
                                            color: "#FF9F0A"
                                            Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutExpo } }
                                        }
                                        Rectangle {
                                            height: parent.height
                                            width: Math.max(6, storageTrack.width * (settingsScope.storageAppsGb / Math.max(1, settingsScope.storageTotalGb)))
                                            color: "#30D158"
                                            Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutExpo } }
                                        }
                                        Rectangle {
                                            height: parent.height
                                            width: Math.max(6, storageTrack.width * (settingsScope.storageMediaGb / Math.max(1, settingsScope.storageTotalGb)))
                                            color: "#0A84FF"
                                            Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutExpo } }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    Row {
                                        spacing: 5
                                        Rectangle { width: 8; height: 8; radius: 4; color: "#FF9F0A"; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: "Sistem (" + settingsScope.storageSysGb.toFixed(0) + " GB)"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    Row {
                                        spacing: 5
                                        Rectangle { width: 8; height: 8; radius: 4; color: "#30D158"; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: "Aplikasi (" + settingsScope.storageAppsGb.toFixed(0) + " GB)"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    Row {
                                        spacing: 5
                                        Rectangle { width: 8; height: 8; radius: 4; color: "#0A84FF"; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: "Media & File (" + settingsScope.storageMediaGb.toFixed(0) + " GB)"; color: ThemeTokens.textSecondary; font.pixelSize: 10 }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: Math.max(0, settingsScope.storageTotalGb - settingsScope.storageUsedGb).toFixed(0) + " GB Tersedia"
                                        color: ThemeTokens.textPrimary; font.pixelSize: 10; font.weight: Font.DemiBold
                                    }
                                }
                            }

                            SettingsGroup {
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: shellRoot.batteryPercent >= 0 ? ("Baterai " + shellRoot.batteryPercent + "% (" + shellRoot.batteryStatus + ")") : "Daya Listrik (AC)"
                                        color: ThemeTokens.textPrimary
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "Uptime " + (shellRoot.sysSpecs.uptimeStr || "-"); color: ThemeTokens.textSecondary; font.pixelSize: 11 }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeTokens.dividerColor }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Mode Energi"; color: ThemeTokens.textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                                    Row {
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { id: "power-saver", label: "Hemat" },
                                                { id: "balanced", label: "Seimbang" },
                                                { id: "performance", label: "Performa" }
                                            ]
                                            Rectangle {
                                                height: 28; width: 78; radius: 7
                                                property bool active: shellRoot.powerProfile === modelData.id
                                                color: active ? ThemeTokens.accent : ThemeTokens.inputBg
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: active ? ThemeTokens.textOnAccent : ThemeTokens.textPrimary
                                                    font.pixelSize: 11
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: settingsScope.setPowerProfile(modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                Text { text: "Sesi & Daya"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Repeater {
                                        model: [
                                            { label: "Lock Screen", act: "lock", cmd: "" },
                                            { label: "Sleep", act: "sleep", cmd: "sleep 0.25; systemctl suspend" },
                                            { label: "Restart...", act: "reboot", cmd: "systemctl reboot || loginctl reboot" },
                                            { label: "Shut Down...", act: "poweroff", cmd: "systemctl poweroff || loginctl poweroff" }
                                        ]

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 36
                                            radius: 9
                                            color: (modelData.act === "poweroff" || modelData.act === "reboot") ? ThemeTokens.inputBg : ThemeTokens.accentSoft
                                            border.width: 1
                                            border.color: (modelData.act === "poweroff" || modelData.act === "reboot") ? ThemeTokens.borderSubtle : ThemeTokens.accent

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: (modelData.act === "poweroff" || modelData.act === "reboot") ? ThemeTokens.danger : ThemeTokens.textPrimary
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.act === "lock") {
                                                        shellRoot.closePopups();
                                                        shellRoot.sessionLocked = true;
                                                    } else if (modelData.act === "sleep") {
                                                        shellRoot.closePopups();
                                                        shellRoot.runCmd(modelData.cmd);
                                                    } else {
                                                        // Buka modal konfirmasi daya yang sama di MenuPopups
                                                        shellRoot.closePopups();
                                                        if (typeof modRoot !== "undefined") {
                                                            modRoot.pendingPowerLabel = modelData.label;
                                                            modRoot.pendingPowerCmd = modelData.cmd;
                                                        } else {
                                                            shellRoot.runCmd(modelData.cmd);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ====================================================
                        // KATEGORI 7: BAHASA & PROFIL PENGGUNA
                        // ====================================================
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: shellRoot.settingsTab === "language_profile"

                            Text {
                                text: LocaleStrings.navLanguageProfile
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                            }

                            // Pilihan Bahasa Antarmuka (ID / EN)
                            SettingsGroup {
                                Text {
                                    text: LocaleStrings.secLanguage
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Repeater {
                                        model: [
                                            { id: "id", title: "Bahasa Indonesia", sub: "Antarmuka & menu dalam Bahasa Indonesia", code: "ID" },
                                            { id: "en", title: "English", sub: "Interface & menus in English", code: "EN" }
                                        ]

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 62
                                            radius: 12
                                            property bool selected: ShellState.language === modelData.id
                                            color: selected ? ThemeTokens.accentSoft : ThemeTokens.inputBg
                                            border.width: selected ? 1.8 : 1
                                            border.color: selected ? ThemeTokens.accent : ThemeTokens.borderSubtle

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 12
                                                spacing: 10

                                                Rectangle {
                                                    width: 32; height: 32; radius: 8
                                                    color: selected ? ThemeTokens.accent : ThemeTokens.cardHoverBg
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.code
                                                        color: selected ? "#FFFFFF" : ThemeTokens.textPrimary
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1
                                                    Text {
                                                        text: modelData.title
                                                        color: ThemeTokens.textPrimary
                                                        font.pixelSize: 13
                                                        font.weight: Font.DemiBold
                                                    }
                                                    Text {
                                                        text: modelData.sub
                                                        color: ThemeTokens.textSecondary
                                                        font.pixelSize: 10
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ShellState.setLanguage(modelData.id);
                                                    ShellState.saveProfile(ShellState.profileName, ShellState.profileAvatar);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Kustomisasi Profil (Nama & Foto Avatar)
                            SettingsGroup {
                                Text {
                                    text: LocaleStrings.secProfile
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 14

                                    Rectangle {
                                        width: 64; height: 64; radius: 32
                                        color: ThemeTokens.accent
                                        border.width: 2
                                        border.color: ThemeTokens.borderStrong
                                        clip: true

                                        Image {
                                            id: previewAvatarImg
                                            anchors.fill: parent
                                            source: ShellState.profileAvatar !== "" ? (ShellState.profileAvatar.startsWith("/") ? ("file://" + ShellState.profileAvatar) : ShellState.profileAvatar) : ""
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                            visible: status === Image.Ready
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: ShellState.profileInitials
                                            color: "#FFFFFF"
                                            font.pixelSize: 20
                                            font.bold: true
                                            visible: previewAvatarImg.status !== Image.Ready
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: LocaleStrings.t("Nama Tampilan", "Display Name")
                                            color: ThemeTokens.textSecondary
                                            font.pixelSize: 11
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 34
                                            radius: 8
                                            color: ThemeTokens.inputBg
                                            border.width: 1
                                            border.color: profileNameInput.activeFocus ? ThemeTokens.accent : ThemeTokens.borderSubtle

                                            TextInput {
                                                id: profileNameInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                verticalAlignment: TextInput.AlignVCenter
                                                text: ShellState.profileName
                                                color: ThemeTokens.textPrimary
                                                font.pixelSize: 13
                                                clip: true
                                                onAccepted: ShellState.saveProfile(text, profileAvatarInput.text)
                                            }
                                        }

                                        Text {
                                            text: LocaleStrings.t("Lokasi File / URL Foto Profil", "Avatar File Path / URL")
                                            color: ThemeTokens.textSecondary
                                            font.pixelSize: 11
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 34
                                                radius: 8
                                                color: ThemeTokens.inputBg
                                                border.width: 1
                                                border.color: profileAvatarInput.activeFocus ? ThemeTokens.accent : ThemeTokens.borderSubtle

                                                TextInput {
                                                    id: profileAvatarInput
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    text: ShellState.profileAvatar
                                                    color: ThemeTokens.textPrimary
                                                    font.pixelSize: 12
                                                    clip: true
                                                    onAccepted: ShellState.saveProfile(profileNameInput.text, text)

                                                    Text {
                                                        anchors.fill: parent
                                                        verticalAlignment: Text.AlignVCenter
                                                        text: "/home/user/Pictures/avatar.png"
                                                        color: ThemeTokens.textMuted
                                                        font.pixelSize: 11
                                                        visible: profileAvatarInput.text === ""
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                height: 34
                                                width: saveProfTxt.implicitWidth + 24
                                                radius: 8
                                                color: ThemeTokens.accent

                                                Text {
                                                    id: saveProfTxt
                                                    anchors.centerIn: parent
                                                    text: LocaleStrings.t("Simpan", "Save")
                                                    color: "#FFFFFF"
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ShellState.saveProfile(profileNameInput.text, profileAvatarInput.text)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
