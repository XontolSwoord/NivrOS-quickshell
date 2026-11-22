import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../core"

Item {
    id: kbRoot
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin
    readonly property bool anyVisible: (kbCard.opacity > 0.01)

    property var parsedBinds: []
    property string filterQuery: ""

    readonly property var filteredBinds: {
        let q = filterQuery.trim().toLowerCase();
        if (q === "") return parsedBinds;
        return parsedBinds.filter(b =>
            b.keys.toLowerCase().indexOf(q) !== -1 ||
            b.desc.toLowerCase().indexOf(q) !== -1 ||
            b.cat.toLowerCase().indexOf(q) !== -1
        );
    }

    Process {
        id: parseNiriBindsProc
        running: true
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/parse_niri_binds.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    kbRoot.parsedBinds = JSON.parse(text.trim() || "[]");
                } catch (e) {}
            }
        }
    }
    Rectangle {
        id: kbCard
        z: 18
        anchors.centerIn: parent
        width: 680
        height: 520
        radius: 22
        color: ThemeTokens.windowBg
        border.width: 1
        border.color: ThemeTokens.borderStrong
        clip: true

        property bool isOpen: shellRoot.activePopup === "keybinds"
        onIsOpenChanged: {
            if (isOpen) {
                filterQuery = "";
                kbSearchInput.text = "";
                parseNiriBindsProc.running = true;
                kbSearchInput.forceActiveFocus();
            }
        }

        opacity: isOpen ? 1.0 : 0.0
        scale: isOpen ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { SpringAnimation { mass: 0.95; spring: 5.8; damping: 0.52; epsilon: 0.001 } }
        visible: !shellRoot.preWarmDone || (isOpen || opacity > 0.01)

        GlassPanel {
            anchors.fill: parent
            z: 0
            radius: 22
            visible: !ShellState.isSolid
            drawRim: false
        }

        MouseArea { anchors.fill: parent; z: 0 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            z: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Simbol vektor keyboard kustom NivrOS
                Rectangle {
                    width: 34; height: 34; radius: 10
                    color: ThemeTokens.accentSoft
                    border.width: 1; border.color: ThemeTokens.accent
                    Canvas {
                        anchors.centerIn: parent
                        width: 20; height: 16
                        property color fg: ThemeTokens.accent
                        onFgChanged: requestPaint()
                        onPaint: {
                            let ctx = getContext("2d"); ctx.reset();
                            ctx.strokeStyle = fg; ctx.fillStyle = fg; ctx.lineWidth = 1.4;
                            ctx.beginPath(); ctx.roundedRect(1.5, 2, 17, 12, 2.5, 2.5); ctx.stroke();
                            for (let r = 0; r < 2; r++) {
                                for (let c = 0; c < 4; c++) {
                                    ctx.fillRect(4 + c * 3.3, 4.5 + r * 3.2, 2.1, 1.8);
                                }
                            }
                            ctx.fillRect(6, 11, 8, 1.6);
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: LocaleStrings.t("Pintasan Keyboard Niri", "Niri Keyboard Shortcuts")
                        color: ThemeTokens.textPrimary
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Text {
                        text: LocaleStrings.t("Dibaca otomatis dari ~/.config/niri/config.kdl • Tekan Super+/ kapan saja", "Auto-parsed from ~/.config/niri/config.kdl • Press Super+/ anytime")
                        color: ThemeTokens.textSecondary
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: closeKbM.containsMouse ? ThemeTokens.cardHoverBg : ThemeTokens.inputBg
                    Text { anchors.centerIn: parent; text: "×"; color: ThemeTokens.textPrimary; font.pixelSize: 15; font.bold: true }
                    MouseArea {
                        id: closeKbM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shellRoot.closePopups()
                    }
                }
            }

            // Kotak Pencarian Cepat
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 10
                color: ThemeTokens.inputBg
                border.width: 1
                border.color: kbSearchInput.activeFocus ? ThemeTokens.accent : ThemeTokens.borderSubtle

                TextInput {
                    id: kbSearchInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: ThemeTokens.textPrimary
                    font.pixelSize: 13
                    onTextChanged: kbRoot.filterQuery = text
                    Keys.onEscapePressed: shellRoot.closePopups()

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: LocaleStrings.t("Cari pintasan (misal: workspace, terminal, close, screenshot)...", "Search shortcuts (e.g. workspace, terminal, close)...")
                        color: ThemeTokens.textMuted
                        font.pixelSize: 12
                        visible: kbSearchInput.text === ""
                    }
                }
            }

            ListView {
        populate: Transition { NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }
                flickDeceleration: 2000
                maximumFlickVelocity: 2800
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: kbRoot.filteredBinds

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 40
                    radius: 10
                    color: ThemeTokens.cardBg
                    border.width: 1
                    border.color: ThemeTokens.borderSubtle

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            height: 22
                            width: catTxt.implicitWidth + 14
                            radius: 6
                            color: ThemeTokens.accentSoft
                            Text {
                                id: catTxt
                                anchors.centerIn: parent
                                text: modelData.cat
                                color: ThemeTokens.accent
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.desc
                            color: ThemeTokens.textPrimary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Row {
                            spacing: 4
                            Repeater {
                                model: String(modelData.keys || "").split("+")
                                Rectangle {
                                    height: 24
                                    width: keyCapTxt.implicitWidth + 14
                                    radius: 6
                                    color: ThemeTokens.inputBg
                                    border.width: 1
                                    border.color: ThemeTokens.borderStrong
                                    Text {
                                        id: keyCapTxt
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: ThemeTokens.textPrimary
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
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
