import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../../config" as Config
import "../../../design/primitives" as Primitives
import "../vm" as QuickSettingsVm
import "./"

/*
  TrayPopover
  Adjacent tray panel with menu handling and tooltip support.
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
    required property int itemHeight
    required property int iconSize
    required property int itemSpacing
    required property int slideOffset
    required property QuickSettingsVm.PopoverState state

    readonly property bool hovered: surface.hovered

    Timer {
        id: tooltipTimer
        interval: root.state.trayTooltipDelay
        repeat: false
        onTriggered: {
            if (root.state.trayTooltipPending) {
                root.state.showTrayTooltip(
                    root.state.trayTooltipPending,
                    root.state.trayTooltipPending.trayTitleClean,
                    root.state.trayTooltipPending.trayDescriptionClean,
                    trayTooltipLayer,
                    root.state.trayTooltipX,
                    root.state.trayTooltipY
                );
            }
        }
    }

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
        blockMask: root.state.trayTooltipVisible
        closedXOffset: root.slideOffset
        closedOpacity: 0

        chromeData: [
            Primitives.CornerCutout {
                visible: root.cornerRadius > 0
                radius: root.cornerRadius
                fillColor: surface.bodyItem.color
                mirrorX: true
                anchors.right: surface.bodyItem.left
                anchors.top: surface.bodyItem.top
            },
            Primitives.CornerCutout {
                visible: root.cornerRadius > 0
                radius: root.cornerRadius
                fillColor: surface.bodyItem.color
                mirrorX: true
                anchors.right: surface.bodyItem.right
                anchors.top: surface.bodyItem.bottom
            }
        ]

        contentData: ColumnLayout {
            anchors.fill: parent
            spacing: Math.max(8, Math.round(root.itemSpacing))

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                asynchronous: true
                active: root.open
                sourceComponent: trayContentComponent
            }

            Component {
                id: trayContentComponent

                TrayList {
                    itemHeight: root.itemHeight
                    iconSize: root.iconSize
                    spacing: root.itemSpacing
                    tooltipLayer: trayTooltipLayer
                    tooltipTimer: tooltipTimer
                    state: root.state
                }
            }

        }

        overlayData: Item {
            id: trayTooltipLayer
            anchors.fill: parent

            TrayTooltip {
                anchors.fill: parent
                state: root.state
                maxWidth: Math.max(160, Math.round(root.widthValue - root.contentPadding * 2))
            }
        }
    }
}
