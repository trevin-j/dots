import QtQuick

import "../config" as Config

NumberAnimation {
    id: root

    property var curve: Config.Motion.standardCurve
    property int durationMs: Config.Motion.shortDuration

    duration: durationMs
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
