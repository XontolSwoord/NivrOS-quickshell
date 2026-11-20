import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
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

    property bool dwellTriggered: false
    property bool startupPeek: false
    property bool shuttingDown: false
    property var runningList: []

    readonly property bool isDockOpen: !(macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false) && (dwellTriggered || startupPeek)
    readonly property bool pointerInsideDock: dockInputHandler.hovered || macDockPill.hoveredSlots > 0

    mask: Region {
        item: macDockMaskItem
    }

    Item {
        id: macDockMaskItem
        readonly property real targetPillW: Math.max(220, macDockPill.width)
        readonly property real targetPillX: (macDockWin.width - targetPillW) * 0.5
        readonly property real activeCoverH: macDockWin.isDockOpen ? 108 : Math.max(4, Math.round(108 - macDockPill.slideY * 1.25))
        readonly property bool visuallyActive: macDockWin.isDockOpen || macDockPill.opacity > 0.05

        x: (macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false) ? 0 : Math.max(0, targetPillX - (visuallyActive ? 24 : 4))
        y: (macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false) ? macDockWin.height : (macDockWin.height - activeCoverH)
        width: (macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false) ? 0 : Math.min(macDockWin.width, targetPillW + (visuallyActive ? 48 : 8))
        height: (macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false) ? 0 : activeCoverH
    }

    onPointerInsideDockChanged: {
        if ((macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false)) return;
        if (pointerInsideDock) {
            macDockHideTimer.stop();
            if (!isDockOpen && !macDockDwellTimer.running) {
                macDockDwellTimer.restart();
            }
        } else {
            macDockDwellTimer.stop();
            macDockPill.pointerActive = false;
            macDockPill.pointerScreenX = -1000;
            if (isDockOpen) {
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

    Connections {
        target: ShellState
        function onEditModeChanged() {
            if ((macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false)) {
                macDockDwellTimer.stop();
                macDockHideTimer.stop();
                macDockWin.dwellTriggered = false;
                macDockWin.startupPeek = false;
            }
        }
    }

    Timer {
        id: macDockStartupTimer
        interval: 1500
        running: true
        repeat: false
        onTriggered: macDockWin.startupPeek = false
    }

    Timer {
        id: macDockDwellTimer
        interval: 110
        repeat: false
        onTriggered: {
            if (!(macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false) && macDockWin.pointerInsideDock) {
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
        interval: 280
        repeat: false
        onTriggered: {
            if (!macDockWin.pointerInsideDock) {
                macDockWin.dwellTriggered = false;
                macDockWin.startupPeek = false;
            }
        }
    }

    function findRunningWinId(matchKey) {
        if (!matchKey || matchKey === "") return -1;
        let key = matchKey.toLowerCase();
        let fallbackId = -1;
        for (let i = runningList.length - 1; i >= 0; i--) {
            let w = runningList[i];
            let appId = (w.app_id || "").toLowerCase();
            if (appId.includes(key)) {
                if (w.is_focused) return w.id;
                if (fallbackId < 0) fallbackId = w.id;
            }
        }
        return fallbackId;
    }

    Process {
        id: macDockEventStream
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                let s = line.trim();
                if (!s) return;
                try {
                    let ev = JSON.parse(s);
                    if (ev.WindowsChanged && Array.isArray(ev.WindowsChanged.windows)) {
                        macDockWin.runningList = ev.WindowsChanged.windows;
                    } else if (ev.WindowOpenedOrChanged && ev.WindowOpenedOrChanged.window) {
                        let w = ev.WindowOpenedOrChanged.window;
                        let next = macDockWin.runningList.filter(item => item.id !== w.id);
                        next.push(w);
                        macDockWin.runningList = next;
                    } else if (ev.WindowClosed && typeof ev.WindowClosed.id === "number") {
                        let closedId = ev.WindowClosed.id;
                        macDockWin.runningList = macDockWin.runningList.filter(item => item.id !== closedId);
                    }
                } catch (e) {}
            }
        }
        onExited: (code, status) => {
            if (!macDockWin.shuttingDown) macDockStreamRestart.restart();
        }
    }

    Timer {
        id: macDockStreamRestart
        interval: 1500
        repeat: false
        onTriggered: if (!macDockWin.shuttingDown) macDockEventStream.running = true
    }

    Component.onDestruction: {
        macDockWin.shuttingDown = true;
        macDockStreamRestart.stop();
        macDockEventStream.running = false;
    }

    Item {
        id: macDockInputRoot
        anchors.fill: parent

        HoverHandler {
            id: dockInputHandler
            enabled: !(macDockWin.shellRoot ? macDockWin.shellRoot.desktopEditMode : false)
            onPointChanged: {
                if (!hovered) return;
                if (macDockWin.isDockOpen) {
                    macDockPill.pointerActive = true;
                    macDockPill.pointerScreenX = point.position.x;
                } else if (!macDockDwellTimer.running) {
                    macDockDwellTimer.restart();
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
            color: "transparent"

            property bool pointerActive: false
            property real pointerScreenX: -1000
            property int hoveredSlots: 0
            property real slideY: macDockWin.isDockOpen ? 0 : 86

            opacity: macDockWin.isDockOpen ? 1.0 : 0.0
            transform: Translate { y: macDockPill.slideY }

            Behavior on slideY {
                SpringAnimation {
                    mass: 1.2
                    spring: 4.4
                    damping: 0.88
                    epsilon: 0.001
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutQuint
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
                screenY: ((macDockWin.screen ? macDockWin.screen.height : Screen.height) || 768) - height - 8
                circular: false
                drawRim: true
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: "#3AFFFFFF"
                z: 1

                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(0, parent.width - 28)
                    height: 1
                    color: "#2CFFFFFF"
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
                    model: [
                        { name: "Finder", icon: "system-file-manager", glyph: "F", bg: "#1E88E5", cmd: "command -v thunar >/dev/null 2>&1 && thunar || xdg-open \"$HOME\"", match: "thunar" },
                        { name: "Launchpad", icon: "view-app-grid-symbolic", glyph: "::", bg: "#5E5CE6", cmd: "", match: "" },
                        { name: "Firefox", icon: "firefox", glyph: "FF", bg: "#FF7139", cmd: "firefox", match: "firefox" },
                        { name: "Terminal", icon: "Alacritty", glyph: ">_", bg: "#1C1C1E", cmd: "alacritty", match: "alacritty" },
                        { name: "Settings", icon: "preferences-system", glyph: "S", bg: "#8E8E93", cmd: "", match: "" }
                    ]

                    Item {
                        id: macDockSlot
                        readonly property bool hasDivider: index > 0 && modelData.name === "Settings"
                        readonly property real targetMag: macDockPill.calcMag(index, hasDivider)
                        property real smoothMag: 1.0
                        property real bounceY: 0
                        property bool launching: false
                        readonly property int winId: macDockWin.findRunningWinId(modelData.match)
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
                                spring: 7.2
                                damping: 0.68
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
                            color: "#38FFFFFF"
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
                            Behavior on scale { SpringAnimation { spring: 6.8; damping: 0.72 } }
                            Behavior on anchors.bottomMargin { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                            Text {
                                id: macTipTxt
                                anchors.centerIn: parent
                                text: modelData.name
                                color: "#F5F5F7"
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
                                source: modelData.icon !== "" ? Quickshell.iconPath(modelData.icon, true) : ""
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
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: {
                                macDockPill.hoveredSlots = Math.max(0, macDockPill.hoveredSlots + (containsMouse ? 1 : -1));
                            }
                            onClicked: {
                                if (modelData.name === "Launchpad") {
                                    macDockBounce.restart();
                                    (macDockWin.shellRoot ? macDockWin.shellRoot.switchPopup : ShellState.switchPopup)("launchpad");
                                } else if (modelData.name === "Settings") {
                                    macDockBounce.restart();
                                    (macDockWin.shellRoot ? macDockWin.shellRoot.switchPopup : ShellState.switchPopup)("settings");
                                } else if (macDockSlot.winId >= 0) {
                                    (macDockWin.shellRoot ? macDockWin.shellRoot.runCmd : ShellState.runCmd)("niri msg action focus-window --id " + macDockSlot.winId);
                                } else if (modelData.cmd && modelData.cmd !== "" && !macDockSlot.launching) {
                                    macDockSlot.launching = true;
                                    launchGuard.restart();
                                    macDockBounce.restart();
                                    (macDockWin.shellRoot ? macDockWin.shellRoot.runCmd : ShellState.runCmd)(modelData.cmd);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
