import QtQuick
import QtQuick.Layouts
import "../core"

Item {
    anchors.fill: parent
    required property var shellRoot
    required property var hostWin

    Item {
        id: wCalendar
        x: hostWin.getWidgetX("calendar")
        y: hostWin.getWidgetY("calendar")
        width: 226
        height: 196
        readonly property bool isOn: hostWin.isWidgetOn("calendar")
        readonly property real baseScale: hostWin.getWidgetScale("calendar")
        property bool entered: false
        Component.onCompleted: entered = true
        opacity: (isOn && entered) ? 1.0 : 0.0
        scale: (isOn && entered) ? baseScale : (baseScale * 0.86)
        visible: opacity > 0.01
        transformOrigin: Item.TopLeft
        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on x { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !dragArea.pressed; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { enabled: !resizeArea.pressed; NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

        property date currentDate: new Date()
        readonly property int yearNum: currentDate.getFullYear()
        readonly property int monthNum: currentDate.getMonth()
        readonly property int todayDate: currentDate.getDate()
        readonly property var monthNames: ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"]

        readonly property var dayCells: {
            let firstDay = new Date(yearNum, monthNum, 1).getDay();
            let daysInMonth = new Date(yearNum, monthNum + 1, 0).getDate();
            let arr = [];
            for (let i = 0; i < firstDay; i++) arr.push(0);
            for (let d = 1; d <= daysInMonth; d++) arr.push(d);
            while (arr.length < 35) arr.push(0);
            return arr.slice(0, 35);
        }

        Timer {
            interval: 60000
            running: wCalendar.visible
            repeat: true
            onTriggered: wCalendar.currentDate = new Date()
        }

        Canvas {
            anchors.fill: parent
            property real dX: wCalendar.x
            property real dY: wCalendar.y
            property real dS: wCalendar.scale
            onDSChanged: requestPaint()
            property real dO: shellRoot.aeroOpacity
            property real dR: shellRoot.aeroReflection
            property string dSt: ShellState.surfaceMode + "_" + ShellState.liquidVariant + "_" + ShellState.colorScheme
            property real dTh: shellRoot.activeGlassDetail
            onDXChanged: requestPaint()
            onDYChanged: requestPaint()
            onDOChanged: requestPaint()
            onDRChanged: requestPaint()
            onDStChanged: requestPaint()
            onDThChanged: requestPaint()
            onPaint: hostWin.drawWidgetGlass(getContext("2d"), width, height, 24, wCalendar.x, wCalendar.y, false)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: wCalendar.monthNames[wCalendar.monthNum] + " " + wCalendar.yearNum
                    color: ThemeTokens.textPrimary
                    font.pixelSize: 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    height: 20; width: dayBadgeTxt.implicitWidth + 12; radius: 6
                    color: ThemeTokens.accentSoft
                    Text {
                        id: dayBadgeTxt
                        anchors.centerIn: parent
                        text: Qt.formatDate(wCalendar.currentDate, "ddd, d")
                        color: ThemeTokens.accent
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: ["M", "S", "S", "R", "K", "J", "S"]
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: index === 0 ? ThemeTokens.danger : ThemeTokens.textMuted
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                Repeater {
                    model: wCalendar.dayCells
                    Rectangle {
                        Layout.fillWidth: true
                        height: 20
                        radius: 6
                        property bool isToday: modelData === wCalendar.todayDate
                        color: isToday ? ThemeTokens.accent : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData > 0 ? String(modelData) : ""
                            color: isToday ? "#FFFFFF" : (index % 7 === 0 ? ThemeTokens.danger : ThemeTokens.textPrimary)
                            font.pixelSize: 10
                            font.bold: isToday
                        }
                    }
                }
            }
        }

        // Klik kanan untuk buka menu konteks widget
        MouseArea {
            anchors.fill: parent
            z: 1
            acceptedButtons: Qt.RightButton
            onClicked: (m) => {
                let p = mapToItem(hostWin.contentItem, m.x, m.y);
                hostWin.openWidgetCtxMenu(p.x, p.y);
            }
        }

        // Drag & drop saat Mode Atur Widget aktif
        MouseArea {
            anchors.fill: parent
            z: 20
            visible: hostWin.editMode && !hostWin.widgetsLocked
            id: dragArea
            cursorShape: Qt.SizeAllCursor
            property real sx: 0; property real sy: 0; property real ox: 0; property real oy: 0
            onPressed: (m) => { hostWin.bringWidgetToFront("calendar"); let p = mapToItem(hostWin.contentItem, m.x, m.y); sx = p.x; sy = p.y; ox = wCalendar.x; oy = wCalendar.y; }
            onPositionChanged: (m) => { if (pressed) { let p = mapToItem(hostWin.contentItem, m.x, m.y); hostWin.setWidgetPos("calendar", ox + (p.x - sx), oy + (p.y - sy)); } }
            onReleased: hostWin.saveLayout()
        }

        // Tombol hapus merah (X) di pojok kiri atas saat Edit Mode
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -6
            z: 25; width: 22; height: 22; radius: 11
            color: "#FF453A"; border.width: 1; border.color: ThemeTokens.textPrimary
            visible: hostWin.editMode
            Text { anchors.centerIn: parent; text: "×"; color: ThemeTokens.textPrimary; font.pixelSize: 13; font.bold: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hostWin.setWidgetEnabled("calendar", false) }
        }

        // Handle Ubah Ukuran Bebas (Sudut Kanan Bawah)
        Rectangle {
            anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: -5
            z: 26; width: 20; height: 20; radius: 10
            color: ThemeTokens.accent; border.width: 1.5; border.color: "#FFFFFF"
            visible: hostWin.editMode && !hostWin.widgetsLocked
            Text { anchors.centerIn: parent; text: "◢"; color: "#FFFFFF"; font.pixelSize: 9 }
            MouseArea {
                anchors.fill: parent
                id: resizeArea
                cursorShape: Qt.SizeFDiagCursor
                property real startX: 0
                property real startScale: 1.0
                onPressed: (m) => {
                    let p = mapToItem(hostWin.contentItem, m.x, m.y);
                    startX = p.x;
                    startScale = hostWin.getWidgetScale("calendar");
                }
                onPositionChanged: (m) => {
                    if (pressed) {
                        let p = mapToItem(hostWin.contentItem, m.x, m.y);
                        let delta = (p.x - startX) / 226.0;
                        hostWin.setWidgetScale("calendar", startScale + delta);
                    }
                }
                onReleased: hostWin.saveLayout()
            }
        }
    }
}
