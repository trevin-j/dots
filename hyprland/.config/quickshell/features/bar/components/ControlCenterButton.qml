import QtQuick

import "../../../config" as Config

/*
  ControlCenterButton
  Compact action button that toggles the right-edge control center.
  Required properties: barHeight, iconFont, active.
*/
Rectangle {
    id: root

    required property int barHeight
    required property string iconFont
    required property bool active

    signal clicked()

    readonly property int horizontalPadding: Math.max(8, Math.round(root.barHeight * 0.25))
    readonly property int verticalPadding: Math.max(5, Math.round(root.barHeight * 0.16))
    readonly property int iconSize: Math.max(16, Math.round(root.barHeight * 0.5))

    color: root.active ? Config.Palette.color("primary") : Config.Palette.color("surface_container")
    radius: Config.Appearance.radiusMedium

    implicitWidth: iconLabel.implicitWidth + root.horizontalPadding * 2
    implicitHeight: Math.max(iconLabel.implicitHeight + root.verticalPadding * 2, Math.round(root.barHeight * 0.6))

    Behavior on color {
        ColorAnimation {
            duration: Config.Motion.shortDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Motion.standardCurve
        }
    }

    Text {
        id: iconLabel

        anchors.centerIn: parent
        text: "tune"
        font.family: root.iconFont
        font.pixelSize: root.iconSize
        font.weight: Font.Medium
        color: root.active ? Config.Palette.color("on_primary") : Config.Palette.color("on_surface")
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
