import QtQuick

import "../../../config" as Config
import "../../../services" as Services
import "../../../utils" as Utils

/*
  KeyboardToggle
  Toggle button for wvkbd on-screen keyboard.
*/
Rectangle {
    id: root

    required property int barHeight
    required property string iconFont

    readonly property int horizontalPadding: Math.max(8, Math.round(root.barHeight * 0.25))
    readonly property int verticalPadding: Math.max(5, Math.round(root.barHeight * 0.16))
    readonly property int iconSize: Math.max(16, Math.round(root.barHeight * 0.5))

    radius: Config.Appearance.radiusMedium
    color: Services.KeyboardService.visible ? Config.Palette.color("primary") : Config.Palette.color("surface_container")

    implicitWidth: iconItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: Utils.Bar.widgetHeight(root.barHeight, iconItem.implicitHeight + root.verticalPadding * 2)

    Behavior on color {
        ColorAnimation {
            duration: Config.Motion.shortDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Motion.standardCurve
        }
    }

    signal clicked()

    Text {
        id: iconItem

        anchors.centerIn: parent
        text: Services.KeyboardService.visible ? "keyboard_hide" : "keyboard"
        color: Services.KeyboardService.visible ? Config.Palette.color("on_primary") : Config.Palette.color("on_surface")
        font.family: root.iconFont
        font.pixelSize: root.iconSize
        font.weight: Font.Medium
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
