import QtQuick
import QtQuick.Layouts

import "../../../design/controls" as Controls

/*
  QuickSettingsGrid
  Toggle grid plus power menu used by quick settings popover.
*/
ColumnLayout {
    id: root

    required property int toggleHeight
    required property int toggleSpacing
    required property string materialFont
    required property var state
    property var controlCenterState: null
    property bool forceCollapseMenus: false

    signal powerAction(string actionId)

    spacing: root.toggleSpacing
    Layout.fillWidth: true

    GridLayout {
        id: toggleGrid

        columns: 2
        columnSpacing: root.toggleSpacing
        rowSpacing: root.toggleSpacing
        Layout.fillWidth: true

        readonly property real columnWidth: Math.max(0, (width - columnSpacing) / columns)

        Controls.QuickToggle {
            label: "Wi-Fi"
            icon: "wifi"
            iconFont: root.materialFont
            active: root.state.connectivity.wifiEnabled
            secondaryText: root.state.connectivity.wifiConnected
                ? root.state.connectivity.wifiSsid
                : (root.state.connectivity.wifiEnabled ? "Not connected" : "")
            Layout.fillWidth: true
            Layout.preferredWidth: toggleGrid.columnWidth
            Layout.preferredHeight: root.toggleHeight
            onToggled: root.state.connectivity.setWifiEnabled(next)
        }

        Controls.QuickToggle {
            label: "Bluetooth"
            icon: "bluetooth"
            iconFont: root.materialFont
            active: root.state.connectivity.bluetoothEnabled
            secondaryText: root.state.connectivity.bluetoothDevices !== ""
                ? root.state.connectivity.bluetoothDevices
                : (root.state.connectivity.bluetoothEnabled ? "No devices" : "")
            Layout.fillWidth: true
            Layout.preferredWidth: toggleGrid.columnWidth
            Layout.preferredHeight: root.toggleHeight
            onToggled: root.state.connectivity.setBluetoothEnabled(next)
        }

        Controls.QuickToggle {
            label: "Airplane"
            icon: "airplanemode_active"
            iconFont: root.materialFont
            active: root.state.connectivity.airplaneEnabled
            Layout.fillWidth: true
            Layout.preferredWidth: toggleGrid.columnWidth
            Layout.preferredHeight: root.toggleHeight
            onToggled: root.state.connectivity.setAirplaneEnabled(next)
        }

        Controls.QuickToggle {
            label: "Do Not Disturb"
            icon: "notifications_off"
            iconFont: root.materialFont
            active: root.state.dndEnabled
            Layout.fillWidth: true
            Layout.preferredWidth: toggleGrid.columnWidth
            Layout.preferredHeight: root.toggleHeight
            onToggled: root.state.setDndEnabled(next)
        }

        Controls.QuickToggle {
            label: "Night Light"
            icon: "nightlight"
            iconFont: root.materialFont
            active: root.state.nightLightEnabled
            Layout.fillWidth: true
            Layout.preferredWidth: toggleGrid.columnWidth
            Layout.preferredHeight: root.toggleHeight
            onToggled: root.state.setNightLightEnabled(next)
        }

        Controls.QuickToggle {
            label: "Dark Mode"
            icon: "dark_mode"
            iconFont: root.materialFont
            active: root.state.darkModeEnabled
            Layout.fillWidth: true
            Layout.preferredWidth: toggleGrid.columnWidth
            Layout.preferredHeight: root.toggleHeight
            onToggled: root.state.setDarkModeEnabled(next)
        }

        Controls.QuickToggle {
            label: "Wallpapers"
            icon: "wallpaper"
            iconFont: root.materialFont
            visible: root.controlCenterState !== null
            active: root.controlCenterState?.wallpaperPickerOpen ?? false
            Layout.fillWidth: true
            Layout.preferredWidth: toggleGrid.columnWidth
            Layout.preferredHeight: visible ? root.toggleHeight : 0
            onToggled: {
                if (root.controlCenterState) {
                    root.controlCenterState.wallpaperPickerOpen = next;
                }
            }
        }

        BitwardenQuickToggle {
            visible: root.controlCenterState !== null
            controlHeight: root.toggleHeight
            iconFont: root.materialFont
            controlCenterOpen: root.controlCenterState?.open ?? false
            Layout.fillWidth: true
            Layout.preferredWidth: toggleGrid.columnWidth
            Layout.preferredHeight: visible ? root.toggleHeight : 0
        }
    }

    Controls.ExpandablePowerMenu {
        iconFont: root.materialFont
        spacing: root.toggleSpacing
        itemHeight: Math.max(36, Math.round(root.toggleHeight * 0.8))
        forceCollapsed: root.forceCollapseMenus
        Layout.fillWidth: true
        onActionTriggered: actionId => root.powerAction(actionId)
    }
}
