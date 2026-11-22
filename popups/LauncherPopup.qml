import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import "../core"

Item {
    id: modRoot
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin
    readonly property bool anyVisible: (launcherCard.opacity > 0.01)

        

        Process {
            id: allAppsScanProc
            running: true
            command: ["python3", "-c", "import os, glob, configparser\ndirs=['/usr/share/applications',os.path.expanduser('~/.local/share/applications'),'/usr/local/share/applications','/var/lib/flatpak/exports/share/applications',os.path.expanduser('~/.local/share/flatpak/exports/share/applications')]\nseen=set(); apps=[]\nfor d in dirs:\n  if not os.path.isdir(d): continue\n  for p in sorted(glob.glob(os.path.join(d,'*.desktop'))):\n    cp=configparser.ConfigParser(interpolation=None)\n    try: cp.read(p,encoding='utf-8')\n    except Exception: continue\n    if 'Desktop Entry' not in cp: continue\n    de=cp['Desktop Entry']\n    if de.get('NoDisplay','false').lower()=='true' or de.get('Hidden','false').lower()=='true': continue\n    if de.get('Type','Application')!='Application': continue\n    name=de.get('Name','').strip(); ex=de.get('Exec','').strip(); ic=de.get('Icon','').strip()\n    gen=de.get('GenericName','').strip(); kw=de.get('Keywords','').strip()\n    if not name or not ex: continue\n    k=name.lower()\n    if k in seen: continue\n    seen.add(k)\n    for code in ['%f','%F','%u','%U','%d','%D','%n','%N','%i','%c','%k','%v','%m']:\n      ex=ex.replace(code,'')\n    ex=' '.join(ex.split())\n    if not ex: continue\n    apps.append((name,ic,ex,gen,kw))\napps.sort(key=lambda x:x[0].lower())\nfor n,ic,ex,gen,kw in apps:\n  clean=lambda s: s.replace('|',' ').replace('\\n',' ').strip()\n  print(f'{clean(n)}|{clean(ic)}|{clean(ex)}|{clean(gen)}|{clean(kw)}')\n"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = text.trim().split("\n").filter(l => l.length > 0);
                    let arr = [];
                    let palette = ["#0A84FF", "#30D158", "#FF9F0A", "#5E5CE6", "#FF375F", "#64D2FF", "#BF5AF2"];
                    for (let i = 0; i < lines.length; i++) {
                        let p = lines[i].split("|");
                        if (p.length >= 3) {
                            arr.push({
                                name: p[0],
                                icon: p[1],
                                cmd: p[2],
                                generic: p[3] || "",
                                keywords: p[4] || "",
                                bg: palette[i % palette.length],
                                glyph: p[0].slice(0, 2).toUpperCase()
                            });
                        }
                    }
                    let hasFinder = arr.some(item => String(item.name || "").toLowerCase() === "finder");
                    if (!hasFinder) {
                        arr.unshift({
                            name: "Finder",
                            generic: "File Manager",
                            keywords: "files folder thunar nautilus explorer",
                            cmd: "command -v thunar >/dev/null 2>&1 && thunar || (command -v nautilus >/dev/null 2>&1 && nautilus || xdg-open \"$HOME\")",
                            icon: "system-file-manager",
                            bg: "#1E88E5",
                            glyph: "FI"
                        });
                    }
                    if (modRoot.shellRoot) {
                        modRoot.shellRoot.allSystemApps = arr;
                    }
                }
            }
        }
        Rectangle {
            id: launcherCard
            z: 15
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: shellRoot.activePopup === "spotlight" ? -42 : -10
            width: shellRoot.activePopup === "spotlight" ? 560 : 720
            height: shellRoot.activePopup === "spotlight" ? 410 : 470
            radius: 26
            color: ShellState.isSolid ? ThemeTokens.windowBg : "transparent"
            Canvas {
                anchors.fill: parent
                z: -1
                visible: !ShellState.isSolid
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
                property real dTh: shellRoot.activeGlassDetail
                onDOChanged: requestPaint()
                onDRChanged: requestPaint()
                onDFChanged: requestPaint()
                onDWChanged: requestPaint()
                onDStChanged: requestPaint()
                onDThChanged: requestPaint()
                onPaint: {
                    let sw = Screen.width || 1366;
                    let sh = Screen.height || 768;
                    let pos = parent.mapToItem(null, 0, 0);
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, parent.radius, pos.x, pos.y, sw, sh, false, false);
                }
            }
            border.width: 1
            border.color: ThemeTokens.borderStrong
            visible: !shellRoot.preWarmDone || ((shellRoot.activePopup === "launchpad" || shellRoot.activePopup === "spotlight") || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0; onPressed: (m) => { launcherSearchInput.forceActiveFocus(); m.accepted = false; } }



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "launchpad" || shellRoot.activePopup === "spotlight")
            property var filteredApps: {
                let q = shellRoot.launcherSearchText.trim().toLowerCase();
                if (q === "") return shellRoot.allSystemApps;
                return shellRoot.allSystemApps.filter(a => String(a.name || '').toLowerCase().includes(q) || String(a.generic || '').toLowerCase().includes(q) || String(a.keywords || '').toLowerCase().includes(q) || String(a.cmd || '').toLowerCase().includes(q));
            }

            onIsOpenChanged: {
                if (isOpen) {
                    launcherSearchInput.text = "";
                    appGridView.currentIndex = 0;
                    appGridView.contentY = 0;
                    launcherSearchInput.forceActiveFocus();
// Scan cukup saat startup & timer agar buka langsung tidak tertahan
                }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: launcherCard.isOpen ? 0 : 18
                Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14
                z: 2

                // Bilah Pencarian Spotlight / Launchpad
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 14
                    color: ThemeTokens.inputBg
                    border.width: 1
                    border.color: launcherSearchInput.activeFocus ? ThemeTokens.accent : ThemeTokens.borderSubtle

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "⌕"
                            color: ThemeTokens.textSecondary
                            font.pixelSize: 18
                        }

                        TextInput {
                            id: launcherSearchInput
                            Layout.fillWidth: true
                            color: ThemeTokens.textPrimary
                            font.pixelSize: 15
                            selectionColor: "#0A84FF"
                            clip: true
                            onTextChanged: { shellRoot.launcherSearchText = text; appGridView.currentIndex = 0; }
                            Keys.onEscapePressed: shellRoot.closePopups()
                            Keys.onLeftPressed: (e) => {
                                if (appGridView.count > 0) {
                                    appGridView.currentIndex = Math.max(0, appGridView.currentIndex - 1);
                                    appGridView.positionViewAtIndex(appGridView.currentIndex, GridView.Contain);
                                    e.accepted = true;
                                }
                            }
                            Keys.onRightPressed: (e) => {
                                if (appGridView.count > 0) {
                                    appGridView.currentIndex = Math.min(appGridView.count - 1, appGridView.currentIndex + 1);
                                    appGridView.positionViewAtIndex(appGridView.currentIndex, GridView.Contain);
                                    e.accepted = true;
                                }
                            }
                            Keys.onUpPressed: (e) => {
                                if (appGridView.count > 0) {
                                    let cols = shellRoot.activePopup === "spotlight" ? 5 : 6;
                                    appGridView.currentIndex = Math.max(0, appGridView.currentIndex - cols);
                                    appGridView.positionViewAtIndex(appGridView.currentIndex, GridView.Contain);
                                    e.accepted = true;
                                }
                            }
                            Keys.onDownPressed: (e) => {
                                if (appGridView.count > 0) {
                                    let cols = shellRoot.activePopup === "spotlight" ? 5 : 6;
                                    appGridView.currentIndex = Math.min(appGridView.count - 1, appGridView.currentIndex + cols);
                                    appGridView.positionViewAtIndex(appGridView.currentIndex, GridView.Contain);
                                    e.accepted = true;
                                }
                            }
                            Keys.onReturnPressed: {
                                if (launcherCard.filteredApps.length > 0) {
                                    let idx = Math.max(0, Math.min(launcherCard.filteredApps.length - 1, appGridView.currentIndex));
                                    let chosen = launcherCard.filteredApps[idx];
                                    shellRoot.closePopups();
                                    shellRoot.runCmd(chosen.cmd);
                                }
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: shellRoot.activePopup === "spotlight" ? LocaleStrings.t("Spotlight — Ketik nama aplikasi...", "Spotlight — Type an app name...") : LocaleStrings.t("Cari Aplikasi di Launchpad...", "Search Launchpad Apps...")
                                color: ThemeTokens.textMuted
                                font.pixelSize: 14
                                visible: launcherSearchInput.text === ""
                            }
                        }

                        Rectangle {
                            width: 52
                            height: 22
                            radius: 6
                            color: ThemeTokens.cardBg
                            Text {
                                anchors.centerIn: parent
                                text: shellRoot.activePopup === "spotlight" ? "Spotlight" : "Launchpad"
                                color: ThemeTokens.textSecondary
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }

                // Grid Ikon Aplikasi macOS
                GridView {
                    id: appGridView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cacheBuffer: 640
                    flickDeceleration: 3400
                    maximumFlickVelocity: 4600
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    currentIndex: 0
                    cellWidth: Math.floor(width / (shellRoot.activePopup === "spotlight" ? 5 : 6))
                    cellHeight: 96
                    model: launcherCard.filteredApps

                    NumberAnimation {
                        id: gridWheelAnim
                        target: appGridView
                        property: "contentY"
                        duration: 135
                        easing.type: Easing.OutCubic
                    }

                    WheelHandler {
                        onWheel: (ev) => {
                            let maxY = Math.max(0, appGridView.contentHeight - appGridView.height);
                            let step = ev.pixelDelta.y !== 0 ? -ev.pixelDelta.y : (-ev.angleDelta.y * 0.75);
                            let base = gridWheelAnim.running ? gridWheelAnim.to : appGridView.contentY;
                            let dest = Math.max(0, Math.min(maxY, base + step));
                            gridWheelAnim.stop();
                            gridWheelAnim.from = appGridView.contentY;
                            gridWheelAnim.to = dest;
                            gridWheelAnim.start();
                        }
                    }

                    delegate: Item {
                        width: appGridView.cellWidth
                        height: appGridView.cellHeight

                        Rectangle {
                            id: appCardRect
                            property bool isSelected: GridView.isCurrentItem
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 16
                            color: (gridItemM.containsMouse || isSelected) ? ThemeTokens.cardHoverBg : "transparent"
                            border.width: isSelected ? 1.5 : 0
                            border.color: isSelected ? ThemeTokens.accent : "transparent"
                            scale: gridItemM.pressed ? 0.92 : ((gridItemM.containsMouse || isSelected) ? 1.05 : 1.0)
                            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                width: parent.width - 8

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 48
                                    height: 48
                                    radius: 12
                                    color: gridIconImg.status === Image.Ready ? "transparent" : modelData.bg

                                    Image {
                                        id: gridIconImg
                                        anchors.fill: parent
                                        source: modelData.icon !== "" ? ShellState.resolveIcon(modelData.icon) : ""
                                        sourceSize: Qt.size(96, 96)
                                        smooth: true
                                        mipmap: true
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.glyph
                                        color: ThemeTokens.textPrimary
                                        font.pixelSize: 16
                                        font.bold: true
                                        visible: gridIconImg.status !== Image.Ready
                                    }
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.name
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            MouseArea {
                                id: gridItemM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let targetCmd = modelData.cmd;
                                    if (targetCmd && targetCmd !== "") {
                                        shellRoot.runCmd(targetCmd);
                                    }
                                    shellRoot.closePopups();
                                }
                            }
                        }
                    }
                }
            }
        }
}
