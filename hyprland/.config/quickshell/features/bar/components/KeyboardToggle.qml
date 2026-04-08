import QtQuick
import QtQuick.Layouts

import "../../../config" as Config
import "../../../services" as Services

/*
  KeyboardToggle
  Toggle button for wvkbd on-screen keyboard.
*/
Rectangle {
    id: root

    required property int barHeight
    property int iconSize: Math.max(14, Math.round(barHeight * 0.45))
    property string materialFont: Config.Appearance.iconFontFamily

    readonly property int horizontalPadding: Math.max(6, Math.round(root.barHeight * 0.15))
    readonly property int verticalPadding: Math.max(4, Math.round(horizontalPadding * 0.6))

    radius: Config.Appearance.radiusMedium
    color: Services.KeyboardService.visible
        ? Config.Palette.color("primary_container")
        : Config.Palette.color("surface_container")

    implicitWidth: iconItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: Math.max(barHeight * 0.6, iconItem.implicitHeight + root.verticalPadding * 2)

    signal clicked()

    TapHandler {
        onTapped: {
            Services.KeyboardService.toggle();
        }
    }

    Text {
        id: iconItem

        anchors.centerIn: parent
        text: Services.KeyboardService.visible ? "keyboard_hide" : "keyboard"
        color: Services.KeyboardService.visible
            ? Config.Palette.color("on_primary_container")
            : Config.Palette.color("on_surface")
        font.family: root.materialFont
        font.pixelSize: root.iconSize
        font.weight: Font.Medium
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}
