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
            command: ["python3", "-c", "import os, glob, json, configparser; dirs=[os.path.expanduser('~/.local/share/applications'),'/usr/share/applications','/usr/local/share/applications','/var/lib/flatpak/exports/share/applications',os.path.expanduser('~/.local/share/flatpak/exports/share/applications')]; cache_fp='/tmp/qs_apps_cache.json'; fp_sig=[]; for d in dirs:\n  if os.path.isdir(d):\n    st=os.stat(d); fp_sig.append((d,st.st_mtime_ns,len(os.listdir(d))))\nsig_str=json.dumps(fp_sig); if os.path.exists(cache_fp):\n  try:\n    c=json.load(open(cache_fp,encoding='utf-8'))\n    if c.get('sig')==sig_str and isinstance(c.get('apps'),list):\n      print(json.dumps(c['apps'])); raise SystemExit(0)\n  except SystemExit:\n    raise\n  except Exception:\n    pass\nseen=set(); apps=[]; palette=['#0A84FF','#30D158','#FF9F0A','#5E5CE6','#FF375F','#64D2FF','#BF5AF2']; for d in dirs:\n  if not os.path.isdir(d): continue\n  for p in sorted(glob.glob(os.path.join(d,'*.desktop'))):\n    cp=configparser.ConfigParser(interpolation=None)\n    try: cp.read(p,encoding='utf-8')\n    except Exception: continue\n    if 'Desktop Entry' not in cp: continue\n    de=cp['Desktop Entry']\n    if de.get('NoDisplay','false').lower()=='true' or de.get('Hidden','false').lower()=='true': continue\n    if de.get('Type','Application')!='Application': continue\n    name=de.get('Name','').strip(); raw_exec=de.get('Exec','').strip()\n    if not name or not raw_exec: continue\n    k=name.lower()\n    if k in seen: continue\n    seen.add(k)\n    clean_cmd=' '.join(t for t in raw_exec.split() if not t.startswith('%'))\n    generic=de.get('GenericName','').strip(); kw=de.get('Keywords','').strip(); ic=de.get('Icon','').strip()\n    idx=len(apps)\n    apps.append({'name':name,'generic':generic,'keywords':kw,'cmd':clean_cmd,'icon':ic,'bg':palette[idx%len(palette)],'glyph':name[:2].upper()})\napps.sort(key=lambda x:x['name'].lower()); try:\n  with open(cache_fp,'w',encoding='utf-8') as f: json.dump({'sig':sig_str,'apps':apps},f)\nexcept Exception:\n  pass\nprint(json.dumps(apps))"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        let parsed = JSON.parse(text.trim());
                        if (Array.isArray(parsed) && modRoot.shellRoot) {
                            let hasFinder = parsed.some(item => String(item.name || '').toLowerCase() === 'finder');
                            if (!hasFinder) {
                                parsed.unshift({
                                    name: 'Finder',
                                    generic: 'File Manager',
                                    keywords: 'files folder thunar nautilus explorer',
                                    cmd: 'command -v thunar >/dev/null 2>&1 && thunar || (command -v nautilus >/dev/null 2>&1 && nautilus || xdg-open "$HOME")',
                                    icon: 'system-file-manager',
                                    bg: '#1E88E5',
                                    glyph: 'FI'
                                });
                            }
                            modRoot.shellRoot.allSystemApps = parsed;
                        }
                    } catch (e) {}
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
            color: "transparent"
            Canvas {
                anchors.fill: parent
                z: -1
                property real dO: shellRoot.aeroOpacity
                property real dR: shellRoot.aeroReflection
                property real dF: shellRoot.glassFade
                property string dW: shellRoot.activeGlassWall
                property string dSt: shellRoot.glassStyle
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
            border.color: "#3CFFFFFF"
            visible: !shellRoot.preWarmDone || ((shellRoot.activePopup === "launchpad" || shellRoot.activePopup === "spotlight") || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }



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
                    launcherSearchInput.forceActiveFocus();
                    if (modRoot.shellRoot && modRoot.shellRoot.triggerAppsScan) {
                        modRoot.shellRoot.triggerAppsScan();
                    } else if (typeof appsScanProc !== "undefined") {
                        appsScanProc.running = false;
                        appsScanProc.running = true;
                    }
                }
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: launcherCard.isOpen ? 0 : 18
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
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
                    color: "#26FFFFFF"
                    border.width: 1
                    border.color: launcherSearchInput.activeFocus ? "#77A1C6FF" : "#28FFFFFF"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "⌕"
                            color: "#AEAEB2"
                            font.pixelSize: 18
                        }

                        TextInput {
                            id: launcherSearchInput
                            Layout.fillWidth: true
                            color: "#F5F5F7"
                            font.pixelSize: 15
                            selectionColor: "#0A84FF"
                            clip: true
                            onTextChanged: shellRoot.launcherSearchText = text
                            Keys.onEscapePressed: shellRoot.closePopups()
                            Keys.onReturnPressed: {
                                if (launcherCard.filteredApps.length > 0) {
                                    let chosen = launcherCard.filteredApps[0];
                                    shellRoot.closePopups();
                                    shellRoot.runCmd(chosen.cmd);
                                }
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: shellRoot.activePopup === "spotlight" ? "Spotlight Search — Ketik nama aplikasi..." : "Cari Aplikasi di Launchpad..."
                                color: "#8E8E93"
                                font.pixelSize: 14
                                visible: launcherSearchInput.text === ""
                            }
                        }

                        Rectangle {
                            width: 52
                            height: 22
                            radius: 6
                            color: "#22FFFFFF"
                            Text {
                                anchors.centerIn: parent
                                text: shellRoot.activePopup === "spotlight" ? "Spotlight" : "Launchpad"
                                color: "#AEAEB2"
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
                    cellWidth: Math.floor(width / (shellRoot.activePopup === "spotlight" ? 5 : 6))
                    cellHeight: 96
                    model: launcherCard.filteredApps

                    delegate: Item {
                        width: appGridView.cellWidth
                        height: appGridView.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 16
                            color: gridItemM.containsMouse ? "#26FFFFFF" : "transparent"
                            scale: gridItemM.pressed ? 0.92 : (gridItemM.containsMouse ? 1.05 : 1.0)
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
                                        source: modelData.icon !== "" ? Quickshell.iconPath(modelData.icon, true) : ""
                                        sourceSize: Qt.size(96, 96)
                                        smooth: true
                                        mipmap: true
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.glyph
                                        color: "#FFFFFF"
                                        font.pixelSize: 16
                                        font.bold: true
                                        visible: gridIconImg.status !== Image.Ready
                                    }
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.name
                                    color: "#F5F5F7"
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
