pragma Singleton
import QtQuick

QtObject {
    id: state

    property bool editMode: false
    property string activePopup: ""
    property string glassStyle: "mac"

    property real macOpacity: 0.33
    property real macFrost: 0.42
    property real aeroBaseOpacity: 0.30
    property real aeroSheenBright: 0.46
    property real aeroSheenWidth: 0.48
    property real liquidOpacity: 0.28
    property real liquidRefraction: 0.64
    property real liquidFringing: 0.45

    readonly property real aeroOpacity: glassStyle === "aero" ? aeroBaseOpacity : (glassStyle === "liquid" ? liquidOpacity : macOpacity)
    readonly property real aeroReflection: glassStyle === "aero" ? aeroSheenBright : (glassStyle === "liquid" ? liquidRefraction : macFrost)
    readonly property real activeGlassDetail: glassStyle === "liquid" ? liquidFringing : aeroSheenWidth

    property var switchPopupHandler: null
    property var runCmdHandler: null
    property var saveLayoutHandler: null

    function switchPopup(name) {
        if (typeof switchPopupHandler === "function") switchPopupHandler(name);
    }

    function runCmd(cmd) {
        if (typeof runCmdHandler === "function") runCmdHandler(cmd);
    }

    function saveLayout() {
        if (typeof saveLayoutHandler === "function") saveLayoutHandler();
    }

    function formatTime(sec) {
        let s = Math.max(0, Math.floor(sec || 0));
        let m = Math.floor(s / 60);
        let r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }
}
