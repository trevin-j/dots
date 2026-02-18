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

    readonly property int itemCount: trayView.count

    ListView {
        id: trayView

        anchors.fill: parent
        visible: count > 0
        clip: false
        spacing: root.spacing
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        cacheBuffer: root.itemHeight * 6
        model: SystemTray.items

        delegate: TrayEntry {
            width: trayView.width
            trayItem: modelData
            itemHeight: root.itemHeight
            iconSize: root.iconSize
            tooltipLayer: root.tooltipLayer
            tooltipTimer: root.tooltipTimer
            state: root.state
        }
    }

    Text {
        visible: trayView.count === 0
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
