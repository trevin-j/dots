import QtQuick
import Quickshell.Services.SystemTray

import "../../../config" as Config
import "../vm" as QuickSettingsVm

/*
  TrayList
  Virtualized list view for system tray entries.
*/
Item {
    id: root

    required property int itemHeight
    required property int iconSize
    required property int spacing
    required property Item tooltipLayer
    required property Timer tooltipTimer
    required property QuickSettingsVm.PopoverState state

    readonly property var trayItems: SystemTray.items.values ?? []
    readonly property int itemCount: trayItems.length

    Flickable {
        id: trayFlick

        anchors.fill: parent
        visible: root.itemCount > 0
        clip: true
        contentWidth: width
        contentHeight: trayColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: trayColumn

            width: trayFlick.width
            spacing: root.spacing

            Repeater {
                model: root.trayItems

                delegate: TrayEntry {
                    required property var modelData

                    width: trayColumn.width
                    trayItem: modelData
                    itemHeight: root.itemHeight
                    iconSize: root.iconSize
                    tooltipLayer: root.tooltipLayer
                    tooltipTimer: root.tooltipTimer
                    state: root.state
                }
            }
        }
    }

    Text {
        visible: root.itemCount === 0
        text: "No tray items"
        font.family: Config.Appearance.fontFamily
        font.weight: Config.Appearance.fontWeight
        font.pixelSize: Config.Appearance.fontSizeMedium
        color: Config.Palette.color("on_surface_variant")
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        height: root.itemHeight
        width: parent.width
    }
}
