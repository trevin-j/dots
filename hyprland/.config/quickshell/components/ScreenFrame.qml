import QtQuick
import QtQuick.Effects

import "../config" as Config

/*!
  ScreenFrame
  Renders a full-screen frame using an inverted mask cutout.
  Required properties: borderThickness, borderRounding, frameColor.
*/
Item {
    id: root

    required property real borderThickness
    required property real borderRounding
    required property color frameColor

    property real leftMargin: 0
    property real topMargin: 0

    readonly property real innerWidth: Math.max(0, width - borderThickness * 2 - leftMargin)
    readonly property real innerHeight: Math.max(0, height - borderThickness * 2 - topMargin)
    readonly property real innerRadius: Math.max(0, Math.min(borderRounding, innerWidth / 2, innerHeight / 2))

    Rectangle {
        id: frameFill

        anchors.fill: parent
        color: root.frameColor
        visible: false
        layer.enabled: true
    }

    Rectangle {
        id: maskRect

        x: root.borderThickness + root.leftMargin
        y: root.borderThickness + root.topMargin
        width: root.innerWidth
        height: root.innerHeight
        radius: root.innerRadius
        color: "#ffffff"
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: frameFill
        maskEnabled: true
        maskInverted: true
        maskSource: maskRect
        maskThresholdMin: Config.Appearance.frameMaskThresholdMin
        maskSpreadAtMin: Config.Appearance.frameMaskSpreadAtMin
    }
}
