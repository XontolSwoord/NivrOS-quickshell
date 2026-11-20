import QtQuick
import QtQuick.Window

Canvas {
    id: glassCanvas

    property real radius: 18
    property real screenX: 0
    property real screenY: 0
    property bool circular: false
    property bool drawRim: true

    readonly property real _op: ShellState.aeroOpacity
    readonly property real _refl: ShellState.aeroReflection
    readonly property string _style: ShellState.glassStyle
    readonly property real _detail: ShellState.activeGlassDetail
    readonly property real _w: width
    readonly property real _h: height
    readonly property real _sw: Screen.width
    readonly property real _sh: Screen.height

    on_OpChanged: requestPaint()
    on_ReflChanged: requestPaint()
    on_StyleChanged: requestPaint()
    on_DetailChanged: requestPaint()
    on_WChanged: requestPaint()
    on_HChanged: requestPaint()
    on_SwChanged: requestPaint()
    on_ShChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onScreenXChanged: requestPaint()
    onScreenYChanged: requestPaint()
    onCircularChanged: requestPaint()
    onDrawRimChanged: requestPaint()

    onPaint: {
        let sw = Screen.width || 1366;
        let sh = Screen.height || 768;
        GlassEngine.drawGlobalAeroGlass(
            getContext("2d"),
            width,
            height,
            radius,
            screenX,
            screenY,
            sw,
            sh,
            circular,
            drawRim
        );
    }
}
