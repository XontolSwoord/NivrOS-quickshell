import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import "../core"

PanelWindow {
    id: macDockWin
    property var shellRoot: null
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 132
    visible: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-macos-dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    readonly property string hideMode: (macDockWin.shellRoot ? macDockWin.shellRoot.dockHideMode : ShellState.dockHideMode) || "smart"
    readonly property bool editActive: !!(macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : ShellState.editMode)
    readonly property var windowsList: (macDockWin.shellRoot && Array.isArray(macDockWin.shellRoot.runningWindows))
                                       ? macDockWin.shellRoot.runningWindows : []

    property bool dwellTriggered: false
    property bool startupPeek: hideMode === "smart"
    property var dockItems: []

    readonly property bool isDockOpen: !editActive
                                       && hideMode !== "always"
                                       && (hideMode === "never" || dwellTriggered || startupPeek)
    property bool pointerInPillZone: false
    readonly property bool pointerInsideDock: pointerInPillZone

    readonly property var pinnedSpecs: [
        {
            name: "Finder",
            icon: "system-file-manager",
            glyph: "F",
            bg: "#1E88E5",
            cmd: "command -v thunar >/dev/null 2>&1 && thunar || xdg-open \"$HOME\"",
            matches: ["thunar", "nautilus", "dolphin", "nemo", "pcmanfm", "org.gnome.nautilus"],
            hasDivider: false
        },
        {
            name: "Launchpad",
            icon: "view-app-grid-symbolic",
            glyph: "::",
            bg: "#5E5CE6",
            cmd: "",
            matches: [],
            hasDivider: false
        },
        {
            name: "Firefox",
            icon: "firefox",
            glyph: "FF",
            bg: "#FF7139",
            cmd: "firefox",
            matches: ["firefox", "zen", "chromium", "brave"],
            hasDivider: false
        },
        {
            name: "Terminal",
            icon: "Alacritty",
            glyph: ">_",
            bg: "#1C1C1E",
            cmd: "command -v ghostty >/dev/null 2>&1 && ghostty || alacritty",
            matches: ["alacritty", "ghostty", "kitty", "foot", "wezterm"],
            hasDivider: false
        }
    ]

    function rebuildDockItems() {
        let items = [];
        let pinnedKeys = [];

        for (let i = 0; i < pinnedSpecs.length; i++) {
            let p = pinnedSpecs[i];
            items.push(p);
            for (let m = 0; m < p.matches.length; m++) {
                pinnedKeys.push(p.matches[m]);
            }
        }

        let seenDynamic = {};
        let wins = macDockWin.windowsList;
        for (let j = 0; j < wins.length; j++) {
            let rawId = (wins[j].app_id || "").trim();
            if (!rawId) continue;
            let lowId = rawId.toLowerCase();

            let isPinned = false;
            for (let k = 0; k < pinnedKeys.length; k++) {
                if (lowId.includes(pinnedKeys[k])) {
                    isPinned = true;
                    break;
                }
            }
            if (isPinned || seenDynamic[lowId]) continue;
            seenDynamic[lowId] = true;

            let label = (macDockWin.shellRoot && macDockWin.shellRoot.formatAppName)
                        ? macDockWin.shellRoot.formatAppName(rawId)
                        : rawId;
            items.push({
                name: label,
                icon: rawId,
                glyph: label.slice(0, 2).toUpperCase(),
                bg: "#3A3A3C",
                cmd: "",
                matches: [lowId],
                hasDivider: false
            });
        }

        items.push({
            name: "Settings",
            icon: "preferences-system",
            glyph: "S",
            bg: "#8E8E93",
            cmd: "",
            matches: [],
            hasDivider: true
        });

        macDockWin.dockItems = items;
    }

    onWindowsListChanged: rebuildDockItems()
    Component.onCompleted: rebuildDockItems()

    mask: Region {
        item: macDockMaskItem
    }

    Item {
        id: macDockMaskItem
        readonly property real targetPillW: Math.max(220, macDockPill.width)
        readonly property real targetPillX: (macDockWin.width - targetPillW) * 0.5
        readonly property real activeCoverH: macDockWin.isDockOpen ? 76 : 6
        readonly property bool visuallyActive: macDockWin.isDockOpen || macDockPill.opacity > 0.05
        readonly property bool disableMask: macDockWin.editActive || macDockWin.hideMode === "always"

        readonly property real closedTriggerW: Math.min(macDockWin.width, targetPillW + 24)
        readonly property real closedTriggerX: Math.max(0, (macDockWin.width - closedTriggerW) * 0.5)

        x: disableMask ? 0 : (visuallyActive ? Math.max(0, targetPillX - 4) : closedTriggerX)
        y: disableMask ? macDockWin.height : (macDockWin.height - activeCoverH)
        width: disableMask ? 0 : (visuallyActive ? Math.min(macDockWin.width, targetPillW + 8) : closedTriggerW)
        height: disableMask ? 0 : activeCoverH
    }

    onPointerInsideDockChanged: {
        if (editActive) return;
        if (pointerInsideDock) {
            macDockHideTimer.stop();
            if (!isDockOpen && !macDockDwellTimer.running) {
                macDockDwellTimer.restart();
            }
        } else {
            macDockDwellTimer.stop();
            macDockPill.pointerActive = false;
            macDockPill.pointerScreenX = -1000;
            if (isDockOpen && hideMode === "smart") {
                macDockHideTimer.restart();
            }
        }
    }

    onIsDockOpenChanged: {
        if (isDockOpen) {
            macDockHideTimer.stop();
        } else {
            macDockPill.pointerActive = false;
            macDockPill.pointerScreenX = -1000;
            macDockPill.hoveredSlots = 0;
        }
    }

    onEditActiveChanged: {
        if (editActive) {
            macDockDwellTimer.stop();
            macDockHideTimer.stop();
            macDockWin.dwellTriggered = false;
            macDockWin.startupPeek = false;
        }
    }

    Timer {
        id: macDockStartupTimer
        interval: 1500
        running: macDockWin.startupPeek
        repeat: false
        onTriggered: macDockWin.startupPeek = false
    }

    Timer {
        id: macDockDwellTimer
        interval: 95
        repeat: false
        onTriggered: {
            if (!macDockWin.editActive && macDockWin.pointerInsideDock) {
                macDockWin.dwellTriggered = true;
                if (dockInputHandler.hovered) {
                    macDockPill.pointerActive = true;
                    macDockPill.pointerScreenX = dockInputHandler.point.position.x;
                }
            }
        }
    }

    Timer {
        id: macDockHideTimer
        interval: 160
        repeat: false
        onTriggered: {
            if (!macDockWin.pointerInsideDock && macDockWin.hideMode === "smart") {
                macDockWin.dwellTriggered = false;
                macDockWin.startupPeek = false;
            }
        }
    }

    Timer {
        id: macDockPointerWatchdog
        interval: 90
        repeat: true
        running: macDockWin.isDockOpen && macDockWin.hideMode === "smart"
        onTriggered: {
            if (!dockInputHandler.hovered) {
                macDockWin.pointerInPillZone = false;
                macDockPill.pointerActive = false;
                macDockPill.pointerScreenX = -1000;
                macDockPill.hoveredSlots = 0;
                if (!macDockHideTimer.running) macDockHideTimer.restart();
            }
        }
    }

    function findRunningWinId(matchKeys) {
        if (!Array.isArray(matchKeys) || matchKeys.length === 0) return -1;
        let wins = macDockWin.windowsList;
        let fallbackId = -1;
        for (let i = wins.length - 1; i >= 0; i--) {
            let w = wins[i];
            let appId = (w.app_id || "").toLowerCase();
            if (!appId) continue;
            for (let m = 0; m < matchKeys.length; m++) {
                if (appId.includes(matchKeys[m])) {
                    if (w.is_focused) return w.id;
                    if (fallbackId < 0) fallbackId = w.id;
                    break;
                }
            }
        }
        return fallbackId;
    }

    Item {
        id: macDockInputRoot
        anchors.fill: parent

        HoverHandler {
            id: dockInputHandler
            enabled: !macDockWin.editActive
            onHoveredChanged: {
                if (!hovered) {
                    macDockWin.pointerInPillZone = false;
                    macDockPill.pointerActive = false;
                    macDockPill.pointerScreenX = -1000;
                    macDockPill.hoveredSlots = 0;
                }
            }
            onPointChanged: {
                if (!hovered) {
                    macDockWin.pointerInPillZone = false;
                    macDockPill.pointerActive = false;
                    macDockPill.pointerScreenX = -1000;
                    return;
                }
                let px = point.position.x;
                let py = point.position.y;
                if (macDockWin.isDockOpen) {
                    let inPillX = (px >= macDockPill.x - 2) && (px <= macDockPill.x + macDockPill.width + 2);
                    let inPillY = (py >= macDockPill.y - 12) && (py <= macDockPill.y + macDockPill.height + 8);
                    macDockWin.pointerInPillZone = (inPillX && inPillY);
                    if (macDockWin.pointerInPillZone) {
                        macDockPill.pointerActive = true;
                        macDockPill.pointerScreenX = px;
                    } else {
                        macDockPill.pointerActive = false;
                        macDockPill.pointerScreenX = -1000;
                    }
                } else {
                    let inTriggerX = (px >= macDockMaskItem.x) && (px <= macDockMaskItem.x + macDockMaskItem.width);
                    let inTriggerY = (py >= macDockWin.height - 8);
                    macDockWin.pointerInPillZone = (inTriggerX && inTriggerY);
                    if (macDockWin.pointerInPillZone && !macDockDwellTimer.running) {
                        macDockDwellTimer.restart();
                    }
                }
            }
        }

        Rectangle {
            id: macDockPill
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            height: 58
            width: Math.round(macDockRow.width + 24)
            radius: 19
            color: ShellState.isSolid ? ThemeTokens.dockBg : "transparent"

            property bool pointerActive: false
            property real pointerScreenX: -1000
            property int hoveredSlots: 0
            property real slideY: macDockWin.isDockOpen ? 0 : 86

            opacity: macDockWin.isDockOpen ? 1.0 : 0.0
            transform: Translate { y: macDockPill.slideY }

            Behavior on slideY {
                SpringAnimation {
                    mass: 1.1
                    spring: 5.0
                    damping: 0.46
                    epsilon: 0.001
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 210
                    easing.type: Easing.OutCubic
                }
            }

            function calcMag(slotIndex, hasSepBefore) {
                if (!pointerActive || pointerScreenX < 0 || !macDockWin.isDockOpen) return 1.0;
                let cnt = macDockRepeater.count;
                if (cnt <= 0) return 1.0;
                let basePitch = 46.0;
                let sepShift = hasSepBefore ? 13.0 : 0.0;
                let restRowW = cnt * 40.0 + Math.max(0, cnt - 1) * 6.0 + (cnt > 1 ? 13.0 : 0.0);
                let restLeftX = (macDockWin.width - restRowW) * 0.5;
                let restCenterX = restLeftX + slotIndex * basePitch + sepShift + 20.0;

                let dist = Math.abs(pointerScreenX - restCenterX);
                let radius = 112.0;
                if (dist >= radius) return 1.0;
                let bell = 0.5 * (1.0 + Math.cos(Math.PI * (dist / radius)));
                return 1.0 + 0.52 * (bell * bell);
            }

            GlassPanel {
                anchors.fill: parent
                z: 0
                radius: parent.radius
                screenX: macDockPill.x
                screenY: ((macDockWin.screen ? macDockWin.screen.height : Screen.height) || 864) - height - 8
                circular: false
                drawRim: true
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: ThemeTokens.borderStrong
                z: 1

                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(0, parent.width - 28)
                    height: 1
                    color: ThemeTokens.borderSubtle
                    visible: !ShellState.isSolid
                }
            }

            Row {
                id: macDockRow
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                z: 2

                Repeater {
                    id: macDockRepeater
                    model: macDockWin.dockItems

                    Item {
                        id: macDockSlot
                        readonly property bool hasDivider: index > 0 && !!modelData.hasDivider
                        readonly property real targetMag: macDockPill.calcMag(index, hasDivider)
                        property real smoothMag: 1.0
                        property real bounceY: 0
                        property bool launching: false
                        readonly property int winId: macDockWin.findRunningWinId(modelData.matches)
                        readonly property bool isRunning: winId >= 0

                        onIsRunningChanged: {
                            if (isRunning) {
                                launching = false;
                                launchGuard.stop();
                            }
                        }

                        Timer {
                            id: launchGuard
                            interval: 8000
                            repeat: false
                            onTriggered: macDockSlot.launching = false
                        }

                        Binding {
                            target: macDockSlot
                            property: "smoothMag"
                            value: macDockSlot.targetMag
                        }

                        Behavior on smoothMag {
                            SpringAnimation {
                                mass: 0.85
                                spring: 6.2
                                damping: 0.45
                                epsilon: 0.001
                            }
                        }

                        readonly property real iconSize: 40.0 * Math.max(1.0, smoothMag)
                        width: Math.round(iconSize + (hasDivider ? 13 : 0))
                        height: 84

                        Rectangle {
                            visible: macDockSlot.hasDivider
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 12
                            width: 1
                            height: 34
                            radius: 0.5
                            color: ThemeTokens.dividerColor
                        }

                        SequentialAnimation {
                            id: macDockBounce
                            NumberAnimation { target: macDockSlot; property: "bounceY"; to: 14; duration: 140; easing.type: Easing.OutQuad }
                            NumberAnimation { target: macDockSlot; property: "bounceY"; to: 0; duration: 160; easing.type: Easing.InQuad }
                            NumberAnimation { target: macDockSlot; property: "bounceY"; to: 6; duration: 100; easing.type: Easing.OutQuad }
                            NumberAnimation { target: macDockSlot; property: "bounceY"; to: 0; duration: 120; easing.type: Easing.InQuad }
                        }

                        Rectangle {
                            anchors.horizontalCenter: macIconSquircle.horizontalCenter
                            anchors.bottom: macIconSquircle.top
                            anchors.bottomMargin: macSlotMouse.containsMouse ? 8 : 4
                            width: Math.round(macTipTxt.implicitWidth + 16)
                            height: 22
                            radius: 6.5
                            color: "#EB1C1C22"
                            border.width: 1
                            border.color: "#3CFFFFFF"
                            opacity: (macSlotMouse.containsMouse && macDockWin.isDockOpen) ? 1.0 : 0.0
                            scale: macSlotMouse.containsMouse ? 1.0 : 0.92
                            visible: opacity > 0.01

                            Behavior on opacity { NumberAnimation { duration: 110; easing.type: Easing.InOutCubic } }
                            Behavior on scale { SpringAnimation { mass: 0.85; spring: 6.2; damping: 0.45; epsilon: 0.001 } }
                            Behavior on anchors.bottomMargin { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                            Text {
                                id: macTipTxt
                                anchors.centerIn: parent
                                text: modelData.name
                                color: ThemeTokens.textPrimary
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            id: macIconSquircle
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.horizontalCenterOffset: macDockSlot.hasDivider ? 6 : 0
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 9 + macDockSlot.bounceY - (macSlotMouse.pressed ? 2 : 0)
                            width: Math.round(macDockSlot.iconSize)
                            height: Math.round(macDockSlot.iconSize)
                            radius: Math.round(10 * Math.max(1.0, macDockSlot.smoothMag))
                            color: macAppImg.status === Image.Ready ? "transparent" : (modelData.bg || "#2C2C2E")

                            Image {
                                id: macAppImg
                                anchors.fill: parent
                                source: modelData.icon !== "" ? ShellState.resolveIcon(modelData.icon) : ""
                                sourceSize: Qt.size(128, 128)
                                smooth: true
                                mipmap: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.glyph || ""
                                color: "#FFFFFF"
                                font.pixelSize: Math.round(13 * Math.max(1.0, macDockSlot.smoothMag))
                                font.bold: true
                                visible: macAppImg.status !== Image.Ready
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2.5
                            anchors.horizontalCenter: macIconSquircle.horizontalCenter
                            width: 4.5
                            height: 4.5
                            radius: 2.25
                            color: "#EBFFFFFF"
                            visible: macDockSlot.isRunning
                        }

                        MouseArea {
                            id: macSlotMouse
                            anchors.fill: parent
                            enabled: macDockWin.isDockOpen
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: {
                                macDockPill.hoveredSlots = Math.max(0, macDockPill.hoveredSlots + (containsMouse ? 1 : -1));
                            }
                            onClicked: (mouse) => {
                                let execFn = macDockWin.shellRoot ? macDockWin.shellRoot.runCmd : ShellState.runCmd;
                                let popupFn = macDockWin.shellRoot ? macDockWin.shellRoot.switchPopup : ShellState.switchPopup;

                                if (modelData.name === "Launchpad") {
                                    macDockBounce.restart();
                                    popupFn("launchpad");
                                } else if (modelData.name === "Settings") {
                                    macDockBounce.restart();
                                    popupFn("settings");
                                } else if (mouse.button === Qt.MiddleButton && modelData.cmd && modelData.cmd !== "") {
                                    macDockBounce.restart();
                                    execFn(modelData.cmd);
                                } else if (macDockSlot.winId >= 0) {
                                    execFn("niri msg action focus-window --id " + macDockSlot.winId);
                                } else if (modelData.cmd && modelData.cmd !== "" && !macDockSlot.launching) {
                                    macDockSlot.launching = true;
                                    launchGuard.restart();
                                    macDockBounce.restart();
                                    execFn(modelData.cmd);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
