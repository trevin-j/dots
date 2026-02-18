import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../../design/primitives" as Primitives
import "../../../services" as Services
import "./"
import "../vm" as QuickSettingsVm

/*
  QuickSettingsPopover
  Popover containing quick toggles and power actions.
*/
Item {
    id: root

    required property ShellScreen screen
    required property bool open
    required property int topMargin
    required property int rightMargin
    required property int widthValue
    required property int targetHeight
    required property int cornerRadius
    required property color surfaceColor
    required property int contentPadding
    required property int toggleHeight
    required property int toggleSpacing
    required property string materialFont
    required property QuickSettingsVm.StatusViewModel state

    readonly property bool hovered: surface.hovered
    readonly property int contentPreferredHeight: Math.round(contentPadding * 2 + quickSettingsGrid.implicitHeight)

    Primitives.AttachedPopoverSurface {
        id: surface

        screen: root.screen
        open: root.open
        topMargin: root.topMargin
        rightMargin: root.rightMargin
        widthValue: root.widthValue
        targetHeight: root.targetHeight
        cornerRadius: root.cornerRadius
        surfaceColor: root.surfaceColor
        contentPadding: root.contentPadding

        chromeData: Primitives.CornerCutout {
            visible: root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: surface.bodyItem.color
            mirrorX: true
            anchors.right: surface.bodyItem.right
            anchors.top: surface.bodyItem.bottom
        }

        contentData: ColumnLayout {
            anchors.fill: parent
            spacing: root.toggleSpacing

            QuickSettingsGrid {
                id: quickSettingsGrid

                toggleHeight: root.toggleHeight
                toggleSpacing: root.toggleSpacing
                materialFont: root.materialFont
                state: root.state
                onPowerAction: actionId => Services.PowerService.trigger(actionId)
            }
        }
    }
}
