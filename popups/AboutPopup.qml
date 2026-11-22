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
    readonly property bool anyVisible: (aboutCard.opacity > 0.01)

        Process {
            id: sysSpecsProc
            Component.onCompleted: running = true
            command: ["python3", "-c", "import os, subprocess, socket, getpass\n\ndef read_first(paths, default=\"\"):\n    for p in paths:\n        try:\n            with open(p, \"r\", encoding=\"utf-8\") as f:\n                v = f.read().strip()\n                if v: return v\n        except Exception:\n            pass\n    return default\n\ndef run_out(cmd, default=\"\"):\n    try:\n        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip() or default\n    except Exception:\n        return default\n\nos_name = \"Linux\"\ntry:\n    with open(\"/etc/os-release\", \"r\", encoding=\"utf-8\") as f:\n        for line in f:\n            if line.startswith(\"PRETTY_NAME=\"):\n                os_name = line.split(\"=\", 1)[1].strip().strip('\"')\n                break\nexcept Exception:\n    pass\n\nkernel = os.uname().release\nprod_ver = read_first([\"/sys/devices/virtual/dmi/id/product_version\"], \"\")\nprod_name = read_first([\"/sys/devices/virtual/dmi/id/product_name\"], \"\")\nif \"thinkpad\" in prod_ver.lower():\n    host_model = prod_ver\nelif prod_name and prod_name.lower() != \"to be filled by o.e.m.\":\n    host_model = prod_name\nelse:\n    host_model = socket.gethostname()\n\nuser_host = f\"{getpass.getuser()}@{socket.gethostname()}\"\n\ncpu_model = \"Processor\"\ncores = os.cpu_count() or 1\ntry:\n    with open(\"/proc/cpuinfo\", \"r\", encoding=\"utf-8\") as f:\n        for line in f:\n            if line.startswith(\"model name\"):\n                raw = line.split(\":\", 1)[1].strip()\n                for junk in [\"(R)\", \"(TM)\", \"with Radeon Graphics\", \"CPU\"]:\n                    raw = raw.replace(junk, \"\")\n                cpu_model = f\"{' '.join(raw.split())} ({cores} Threads)\"\n                break\nexcept Exception:\n    pass\n\ngpu_raw = run_out(\"lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -n1 | cut -d':' -f3-\", \"Integrated Graphics\")\ngpu_model = gpu_raw.split(\"(rev\")[0].strip()\nif \"[\" in gpu_model and \"]\" in gpu_model:\n    parts = [p.split(\"]\")[0] for p in gpu_model.split(\"[\")[1:]]\n    if parts:\n        gpu_model = \"AMD \" + parts[-1] if \"amd\" in gpu_raw.lower() or \"ati\" in gpu_raw.lower() else parts[-1]\n\nmem_tot_kb = 1\nmem_avail_kb = 0\ntry:\n    with open(\"/proc/meminfo\", \"r\", encoding=\"utf-8\") as f:\n        for line in f:\n            if line.startswith(\"MemTotal:\"):\n                mem_tot_kb = int(line.split()[1])\n            elif line.startswith(\"MemAvailable:\"):\n                mem_avail_kb = int(line.split()[1])\nexcept Exception:\n    pass\nmem_used_kb = max(0, mem_tot_kb - mem_avail_kb)\nram_used = f\"{mem_used_kb / 1048576:.1f} GiB\"\nram_total = f\"{mem_tot_kb / 1048576:.1f} GiB\"\nram_pct = int(round((mem_used_kb / max(1, mem_tot_kb)) * 100))\n\ndf_out = run_out(\"df -BG --output=used,size,pcent / | tail -n1\", \"0G 0G 0%\").split()\ndisk_used = df_out[0].replace(\"G\", \" GB\") if len(df_out) >= 1 else \"0 GB\"\ndisk_total = df_out[1].replace(\"G\", \" GB\") if len(df_out) >= 2 else \"0 GB\"\ndisk_pct = int(df_out[2].replace(\"%\", \"\")) if len(df_out) >= 3 and df_out[2].replace(\"%\", \"\").isdigit() else 0\n\ndisp = run_out(\"niri msg outputs 2>/dev/null | grep -E 'Current mode:' | head -n1 | sed 's/.*Current mode: //'\", \"\")\nif not disp:\n    disp = read_first([\"/sys/class/drm/card0-eDP-1/modes\", \"/sys/class/drm/card1-eDP-1/modes\"], \"1920x1080\").splitlines()[0]\n\nup_str = run_out(\"uptime -p 2>/dev/null | sed 's/^up //'\", \"-\")\nwm_ver = run_out(\"niri --version 2>/dev/null | awk '{print $1\" \"$2}'\", \"Niri Wayland\")\nqs_ver = run_out(\"qs --version 2>/dev/null | head -n1\", \"Quickshell\")\n\nfields = [os_name, kernel, host_model, user_host, cpu_model, gpu_model, ram_used, ram_total, str(ram_pct), disk_used, disk_total, str(disk_pct), disp, up_str, wm_ver, qs_ver]\nprint(\"|\".join(x.replace(\"|\", \" \") for x in fields))"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let p = text.trim().split("|");
                    if (p.length >= 16) {
                        shellRoot.sysSpecs = {
                            osName: p[0],
                            kernel: p[1],
                            hostModel: p[2],
                            userHost: p[3],
                            cpuModel: p[4],
                            gpuModel: p[5],
                            ramUsed: p[6],
                            ramTotal: p[7],
                            ramPct: parseInt(p[8]) || 0,
                            diskUsed: p[9],
                            diskTotal: p[10],
                            diskPct: parseInt(p[11]) || 0,
                            displayInfo: p[12],
                            uptimeStr: p[13],
                            wmVer: p[14],
                            shellVer: p[15]
                        };
                    }
                }
            }
        }
        Timer {
            id: copiedToastTimer
            interval: 1800
            repeat: false
            onTriggered: shellRoot.copiedBannerMsg = ""
        }
        Rectangle {
            id: aboutCard
            z: 16
            anchors.centerIn: parent
            width: 760
            height: 468
            radius: 28
            color: ThemeTokens.windowBg
            border.width: 1
            border.color: ThemeTokens.borderStrong
            clip: true
            visible: !shellRoot.preWarmDone || (shellRoot.activePopup === "about" || opacity > 0.01)

            MouseArea { anchors.fill: parent; z: 0 }

            // Lapisan Windows 7 Aero + iOS Liquid Glass Real-Time
            Canvas {
                anchors.fill: parent
                z: 0
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
                    shellRoot.drawGlobalAeroGlass(getContext("2d"), width, height, 28, (sw - width) * 0.5, (sh - height) * 0.5, sw, sh, false, false);
                }
            }

            // Specular highlight atas ala Liquid Glass
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 1
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                height: 1
                color: ThemeTokens.cardHoverBg
            }



            property bool _mounted: false
            Timer { interval: 1; running: true; repeat: false; onTriggered: parent._mounted = true }
            property bool isOpen: _mounted && (shellRoot.activePopup === "about")
            property int stage: 0

            onIsOpenChanged: {
                if (isOpen) {
                    shellRoot.copiedBannerMsg = "";
                    sysSpecsProc.running = false;
                    sysSpecsProc.running = true;
                    stage = 1;
                    aboutStaggerTimer.restart();
                    aboutKeyCatcher.forceActiveFocus();
                } else {
                    aboutStaggerTimer.stop();
                    stage = 0;
                }
            }

            Timer {
                id: aboutStaggerTimer
                interval: 34
                repeat: true
                onTriggered: {
                    if (aboutCard.stage < 6) aboutCard.stage++;
                    else stop();
                }
            }

            Item {
                id: aboutKeyCatcher
                focus: aboutCard.isOpen
                Keys.onEscapePressed: shellRoot.closePopups()
            }

            opacity: isOpen ? 1.0 : 0.0
            scale: isOpen ? 1.0 : 0.90
            transform: Translate {
                y: aboutCard.isOpen ? 0 : 14
                Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
            }

            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14
                z: 2

                // ── TOP BAR JENDELA ─────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Row {
                        spacing: 7
                        Rectangle {
                            width: 12; height: 12; radius: 6
                            color: closeAboutM.containsMouse ? "#FF3B30" : "#FF5F56"
                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: "#4D0000"
                                font.pixelSize: 10
                                font.bold: true
                                visible: closeAboutM.containsMouse
                            }
                            MouseArea {
                                id: closeAboutM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shellRoot.closePopups()
                            }
                        }
                        Rectangle { width: 12; height: 12; radius: 6; color: "#FFBD2E" }
                        Rectangle { width: 12; height: 12; radius: 6; color: "#27C93F" }
                    }

                    Item { width: 6 }

                    Text {
                        text: "About System"
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Rectangle {
                        height: 21
                        width: badgeRomTxt.implicitWidth + 14
                        radius: 10.5
                        color: ThemeTokens.cardHoverBg
                        border.width: 1
                        border.color: ThemeTokens.borderStrong
                        Text {
                            id: badgeRomTxt
                            anchors.centerIn: parent
                            text: ShellState.osFullName
                            color: ThemeTokens.textPrimary
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Toast notifikasi saat baris spesifikasi disalin
                    Rectangle {
                        height: 24
                        width: toastTxt.implicitWidth + 16
                        radius: 12
                        color: "#4432D74B"
                        border.width: 1
                        border.color: "#7732D74B"
                        visible: shellRoot.copiedBannerMsg !== ""
                        Text {
                            id: toastTxt
                            anchors.centerIn: parent
                            text: shellRoot.copiedBannerMsg
                            color: "#E5FFE9"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    // Tombol Copy All Specs
                    Rectangle {
                        height: 26
                        width: copyAllTxt.implicitWidth + 18
                        radius: 13
                        color: copyAllM.containsMouse ? "#38FFFFFF" : "#22FFFFFF"
                        border.width: 1
                        border.color: ThemeTokens.borderStrong
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Text {
                            id: copyAllTxt
                            anchors.centerIn: parent
                            text: "Copy All Specs"
                            color: ThemeTokens.textPrimary
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: copyAllM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let s = shellRoot.sysSpecs;
                                let summary = "Device: " + s.hostModel + " (" + s.userHost + ")\n"
                                            + "OS: " + s.osName + " | Kernel: " + s.kernel + "\n"
                                            + "Shell: " + s.wmVer + " + " + s.shellVer + "\n"
                                            + "CPU: " + s.cpuModel + "\n"
                                            + "GPU: " + s.gpuModel + " (" + s.displayInfo + ")\n"
                                            + "RAM: " + s.ramUsed + " / " + s.ramTotal + "\n"
                                            + "Disk: " + s.diskUsed + " / " + s.diskTotal;
                                shellRoot.runCmd("printf \'%s\' \"" + summary.replace(/"/g, "\'") + "\" | wl-copy");
                                shellRoot.copiedBannerMsg = "All Specs Copied ✓";
                                copiedToastTimer.restart();
                            }
                        }
                    }
                }

                // ── BODY: KIRI HERO BANNER WALLPAPER | KANAN CUSTOM ROM LIST ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 18

                    // KOLOM KIRI: BANNER WALLPAPER ALA CUSTOM ROM HP
                    ColumnLayout {
                        Layout.preferredWidth: 284
                        Layout.fillHeight: true
                        spacing: 9

                        opacity: aboutCard.stage >= 1 ? 1.0 : 0.0
                        transform: Translate {
                            y: aboutCard.stage >= 1 ? 0 : 12
                            Behavior on y { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }
                        }
                        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                        Rectangle {
                            id: romHeroBanner
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 22
                            color: "#22222C"
                            border.width: 1
                            border.color: ThemeTokens.borderStrong
                            clip: true
                            scale: bannerM.pressed ? 0.97 : 1.0
                            Behavior on scale { SpringAnimation { mass: 1.05; spring: 5.2; damping: 0.44; epsilon: 0.001 } }

                            Image {
                                id: bannerWallpaperImg
                                anchors.fill: parent
                                source: shellRoot.currentWallpaper
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                mipmap: true
                                visible: status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#28000000" }
                                    GradientStop { position: 0.55; color: "#44000000" }
                                    GradientStop { position: 1.0; color: "#88000000" }
                                }
                            }

                            // Ikon refresh wallpaper di sudut kanan atas banner
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 12
                                width: 28
                                height: 28
                                radius: 14
                                color: bannerM.containsMouse ? "#66FFFFFF" : "#34000000"
                                border.width: 1
                                border.color: ThemeTokens.borderStrong

                                Text {
                                    anchors.centerIn: parent
                                    text: "↻"
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            // Judul Tengah "KAIRO DESKTOP"
                            Item {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -8
                                width: parent.width - 20
                                height: 46

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: 2
                                    text: ShellState.osFullName.toUpperCase()
                                    color: "#A6000000"
                                    font.pixelSize: 24
                                    font.weight: Font.Black
                                    font.letterSpacing: 1
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: ShellState.osFullName.toUpperCase()
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 24
                                    font.weight: Font.Black
                                    font.letterSpacing: 1
                                }
                            }

                            // Pill Bawah Banner
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 16
                                width: parent.width - 24
                                height: 29
                                radius: 14.5
                                color: "#78141210"
                                border.width: 1
                                border.color: "#40FFFFFF"

                                Text {
                                    anchors.centerIn: parent
                                    text: "FLUID TILING • GLASS EXPERIENCE"
                                    color: ThemeTokens.textPrimary
                                    font.pixelSize: 9
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width - 14
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: bannerM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shellRoot.pickRandomWallpaper()
                            }
                        }

                        // Kartu Developer NivrOS
                        Rectangle {
                            Layout.fillWidth: true
                            height: 46
                            radius: 14
                            color: devM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.cardBg
                            border.width: 1
                            border.color: ThemeTokens.borderSubtle
                            Behavior on color { ColorAnimation { duration: 140 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Rectangle {
                                    width: 26; height: 26; radius: 13
                                    color: "#000000"
                                    border.width: 1
                                    border.color: "#38FFFFFF"
                                    Image {
                                        anchors.centerIn: parent
                                        source: "../assets/nos_logo.png"
                                        width: 16
                                        height: 16
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: ShellState.osFullName + " • " + ShellState.developerName
                                        color: ThemeTokens.textPrimary
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: ShellState.developerGithub
                                        color: ThemeTokens.accent
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: "↗"
                                    color: ThemeTokens.textSecondary
                                    font.pixelSize: 12
                                }
                            }

                            MouseArea {
                                id: devM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shellRoot.runCmd("xdg-open '" + ShellState.developerUrl + "' >/dev/null 2>&1 &")
                            }
                        }
                    }

                    // KOLOM KANAN: DAFTAR KARTU SPESIFIKASI ALA CUSTOM ROM HP
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        // Subheader ala ROM HP
                        Text {
                            Layout.fillWidth: true
                            text: "System & hardware specifications — click any row to copy"
                            color: "#D1D1D6"
                            font.pixelSize: 11
                            opacity: aboutCard.stage >= 1 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                        }

                        // Container Kartu Utama Transparan
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 22
                            color: "#5214151E"
                            border.width: 1
                            border.color: ThemeTokens.borderStrong

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 6

                                // BARIS 1: DEVICE & HOST
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 13
                                    color: row1M.containsMouse ? "#26FFFFFF" : "transparent"
                                    opacity: aboutCard.stage >= 2 ? 1.0 : 0.0
                                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 10
                                        spacing: 12

                                        Rectangle {
                                            width: 36; height: 36; radius: 12; color: "#3DF4B8E4"
                                            Text { anchors.centerIn: parent; text: "💻"; font.pixelSize: 16 }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: shellRoot.sysSpecs.hostModel; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: "Host: " + shellRoot.sysSpecs.userHost; color: ThemeTokens.textSecondary; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                        Text { text: "›"; color: ThemeTokens.textSecondary; font.pixelSize: 16; font.bold: true }
                                    }

                                    MouseArea {
                                        id: row1M; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.runCmd("printf \'%s\' \"" + shellRoot.sysSpecs.hostModel + " (" + shellRoot.sysSpecs.userHost + ")\" | wl-copy");
                                            shellRoot.copiedBannerMsg = "Device Info Copied ✓";
                                            copiedToastTimer.restart();
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#1FFFFFFF" }

                                // BARIS 2: OS & KERNEL
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 13
                                    color: row2M.containsMouse ? "#26FFFFFF" : "transparent"
                                    opacity: aboutCard.stage >= 3 ? 1.0 : 0.0
                                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 10
                                        spacing: 12

                                        Rectangle {
                                            width: 36; height: 36; radius: 12; color: "#3D89B4FA"
                                            Text { anchors.centerIn: parent; text: "🐧"; font.pixelSize: 16 }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: shellRoot.sysSpecs.osName; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: "Kernel " + shellRoot.sysSpecs.kernel; color: ThemeTokens.textSecondary; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                        Text { text: "›"; color: ThemeTokens.textSecondary; font.pixelSize: 16; font.bold: true }
                                    }

                                    MouseArea {
                                        id: row2M; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.runCmd("printf \'%s\' \"" + shellRoot.sysSpecs.osName + " | Kernel " + shellRoot.sysSpecs.kernel + "\" | wl-copy");
                                            shellRoot.copiedBannerMsg = "OS & Kernel Copied ✓";
                                            copiedToastTimer.restart();
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#1FFFFFFF" }

                                // BARIS 3: COMPOSITOR & SHELL
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 13
                                    color: row3M.containsMouse ? "#26FFFFFF" : "transparent"
                                    opacity: aboutCard.stage >= 4 ? 1.0 : 0.0
                                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 10
                                        spacing: 12

                                        Rectangle {
                                            width: 36; height: 36; radius: 12; color: "#3DA6E3A1"
                                            Text { anchors.centerIn: parent; text: "✦"; color: "#A6E3A1"; font.pixelSize: 16; font.bold: true }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: shellRoot.sysSpecs.wmVer + " • " + shellRoot.sysSpecs.shellVer; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: "Wayland Custom Desktop Shell"; color: ThemeTokens.textSecondary; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                        Text { text: "›"; color: ThemeTokens.textSecondary; font.pixelSize: 16; font.bold: true }
                                    }

                                    MouseArea {
                                        id: row3M; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.runCmd("printf \'%s\' \"" + shellRoot.sysSpecs.wmVer + " + " + shellRoot.sysSpecs.shellVer + "\" | wl-copy");
                                            shellRoot.copiedBannerMsg = "Shell Info Copied ✓";
                                            copiedToastTimer.restart();
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#1FFFFFFF" }

                                // BARIS 4: PROCESSOR & GRAPHICS
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 13
                                    color: row4M.containsMouse ? "#26FFFFFF" : "transparent"
                                    opacity: aboutCard.stage >= 5 ? 1.0 : 0.0
                                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 10
                                        spacing: 12

                                        Rectangle {
                                            width: 36; height: 36; radius: 12; color: "#3DCBA6F7"
                                            Text { anchors.centerIn: parent; text: "⚙"; color: "#CBA6F7"; font.pixelSize: 17; font.bold: true }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: shellRoot.sysSpecs.cpuModel; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: shellRoot.sysSpecs.gpuModel + " (" + shellRoot.sysSpecs.displayInfo + ")"; color: ThemeTokens.textSecondary; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                        Text { text: "›"; color: ThemeTokens.textSecondary; font.pixelSize: 16; font.bold: true }
                                    }

                                    MouseArea {
                                        id: row4M; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.runCmd("printf \'%s\' \"" + shellRoot.sysSpecs.cpuModel + " | " + shellRoot.sysSpecs.gpuModel + "\" | wl-copy");
                                            shellRoot.copiedBannerMsg = "CPU & GPU Copied ✓";
                                            copiedToastTimer.restart();
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#1FFFFFFF" }

                                // BARIS 5: MEMORY & STORAGE
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 13
                                    color: row5M.containsMouse ? "#26FFFFFF" : "transparent"
                                    opacity: aboutCard.stage >= 6 ? 1.0 : 0.0
                                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 10
                                        spacing: 12

                                        Rectangle {
                                            width: 36; height: 36; radius: 12; color: "#3D94E2D5"
                                            Text { anchors.centerIn: parent; text: "▤"; color: "#94E2D5"; font.pixelSize: 15; font.bold: true }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 4
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: "RAM " + shellRoot.sysSpecs.ramUsed + " / " + shellRoot.sysSpecs.ramTotal; color: ThemeTokens.textPrimary; font.pixelSize: 12; font.bold: true }
                                                Item { Layout.fillWidth: true }
                                                Text { text: "Disk " + shellRoot.sysSpecs.diskUsed + " / " + shellRoot.sysSpecs.diskTotal; color: ThemeTokens.textSecondary; font.pixelSize: 11 }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 5
                                                radius: 2.5
                                                color: ThemeTokens.cardHoverBg
                                                Rectangle {
                                                    width: Math.min(parent.width, parent.width * (shellRoot.sysSpecs.ramPct / 100))
                                                    height: 5
                                                    radius: 2.5
                                                    color: "#94E2D5"
                                                    Behavior on width { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                                                }
                                            }
                                        }
                                        Text { text: "›"; color: ThemeTokens.textSecondary; font.pixelSize: 16; font.bold: true }
                                    }

                                    MouseArea {
                                        id: row5M; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.runCmd("printf \'%s\' \"RAM " + shellRoot.sysSpecs.ramUsed + "/" + shellRoot.sysSpecs.ramTotal + " | Disk " + shellRoot.sysSpecs.diskUsed + "/" + shellRoot.sysSpecs.diskTotal + "\" | wl-copy");
                                            shellRoot.copiedBannerMsg = "Memory & Disk Copied ✓";
                                            copiedToastTimer.restart();
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
