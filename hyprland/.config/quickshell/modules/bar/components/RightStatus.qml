import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import "../../../config" as Config
import "../../../components" as Shared
import "../../../services" as Services
import "../../../utils"

/*!
  RightStatus
  Displays wifi strength, battery, date, and time in a pill.
  Required properties: barHeight, spacing.
*/
Item {
    id: root

    required property int barHeight
    required property int spacing

    readonly property int horizontalPadding: Math.max(6, Math.round(spacing * 0.75))
    readonly property int verticalPadding: Math.max(4, Math.round(horizontalPadding * 0.6))
    readonly property int iconSize: Math.max(14, Math.round(barHeight * 0.45))
    readonly property string materialFont: "Material Symbols Rounded"

    readonly property int popdownWidth: Math.max(320, Math.round(barHeight * 10.5))
    readonly property int popdownPadding: Math.max(12, Math.round(spacing * 1.6))
    readonly property int popdownOffset: 0
    readonly property int popdownCloseDelay: 140
    readonly property int barThickness: Config.Config.bar.size?.thickness ?? barHeight
    readonly property real barCornerRadius: Math.min(Config.Appearance.radiusLarge, barThickness * 0.5)
    readonly property color barColor: Config.Palette.color("surface")
    readonly property int toggleHeight: Math.max(52, Math.round(barHeight * 1.6))
    readonly property int toggleSpacing: Math.max(12, Math.round(spacing * 1.5))
    readonly property int popdownMinHeight: Math.max(260, popdownPadding * 2 + toggleHeight * 4 + toggleSpacing * 3)
    property int popdownTargetHeight: popdownMinHeight
    readonly property int barMargin: Config.Config.bar.size?.margin ?? 10
    readonly property int barMarginTop: Config.Config.bar.size?.marginTop ?? barMargin

    Component.onCompleted: updatePopdownTarget()

    readonly property var windowTransform: QSWindow.window?.windowTransform
    readonly property rect pillRect: {
        windowTransform;
        return QSWindow.window ? QSWindow.window.itemRect(pill) : Qt.rect(0, 0, 0, 0);
    }

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryReady: batteryDevice?.ready ?? false
    readonly property real batteryRawPercent: batteryReady ? batteryDevice.percentage : 0
    readonly property int batteryPercent: batteryReady ? Math.round(batteryRawPercent <= 1 ? batteryRawPercent * 100 : batteryRawPercent) : 0
    readonly property bool batteryLow: batteryReady && batteryPercent <= 10
    readonly property bool batteryCharging: batteryReady
        && (batteryDevice.state === UPowerDeviceState.Charging
            || batteryDevice.state === UPowerDeviceState.PendingCharge)

    readonly property string batteryIconName: {
        if (!batteryReady) {
            return "battery_unknown";
        }
        if (batteryCharging) {
            return "battery_charging_full";
        }
        if (batteryPercent >= 95) {
            return "battery_full";
        }
        if (batteryPercent >= 75) {
            return "battery_6_bar";
        }
        if (batteryPercent >= 60) {
            return "battery_5_bar";
        }
        if (batteryPercent >= 45) {
            return "battery_4_bar";
        }
        if (batteryPercent >= 30) {
            return "battery_3_bar";
        }
        if (batteryPercent >= 15) {
            return "battery_2_bar";
        }
        if (batteryPercent >= 8) {
            return "battery_1_bar";
        }
        return "battery_0_bar";
    }

    readonly property color batteryTextColor: batteryLow ? Config.Palette.color("error") : Config.Palette.color("on_surface")

    readonly property int wifiStrength: Services.ConnectivityService.wifiStrength
    readonly property bool wifiConnected: Services.ConnectivityService.wifiConnected
    readonly property bool ethernetConnected: Services.ConnectivityService.ethernetConnected

    readonly property string wifiIconName: {
        if (ethernetConnected) {
            return "settings_ethernet";
        }
        if (!wifiConnected) {
            return "wifi_off";
        }
        if (wifiStrength >= 70) {
            return "wifi";
        }
        if (wifiStrength >= 40) {
            return "wifi_2_bar";
        }
        return "wifi_1_bar";
    }

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property real volumeLevel: defaultSink?.audio?.volume ?? 0
    readonly property bool volumeMuted: defaultSink?.audio?.muted ?? false

    property bool dndEnabled: false
    property bool nightLightEnabled: false
    property bool darkModeEnabled: false

    readonly property string volumeIconName: {
        if (volumeMuted || volumeLevel <= 0) {
            return "volume_off";
        }
        if (volumeLevel < 0.3) {
            return "volume_mute";
        }
        if (volumeLevel < 0.7) {
            return "volume_down";
        }
        return "volume_up";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function formatTime(dateValue) {
        return Qt.formatDateTime(dateValue, "h:mm AP");
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight


    readonly property int popdownTop: Math.max(0, Math.round(barMarginTop + barThickness - barCornerRadius * 2 + popdownOffset))

    function updatePopdownHold() {
        if (pillHover.containsMouse || popdownHover.containsMouse) {
            closeHold = false;
            closeTimer.stop();
            return;
        }
        closeHold = true;
        closeTimer.restart();
    }

    property bool closeHold: false
    readonly property bool popdownOpen: pillHover.containsMouse || popdownHover.containsMouse || closeHold

    Rectangle {
        id: pill

        radius: Config.Appearance.radiusMedium
        color: Config.Palette.color("surface_container")

        PwObjectTracker {
            objects: [root.defaultSink]
        }

        implicitWidth: contentRow.implicitWidth + root.horizontalPadding * 2
        implicitHeight: Math.max(contentRow.implicitHeight + root.verticalPadding * 2, Math.round(root.barHeight * 0.6))

        RowLayout {
            id: contentRow

            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
            anchors.topMargin: root.verticalPadding
            anchors.bottomMargin: root.verticalPadding
            spacing: root.spacing

            Text {
                id: wifiIcon

                text: root.wifiIconName
                color: Config.Palette.color("on_surface")
                font.family: root.materialFont
                font.pixelSize: root.iconSize
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter

                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: volumeIcon

                text: root.volumeIconName
                color: Config.Palette.color("on_surface")
                font.family: root.materialFont
                font.pixelSize: root.iconSize
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter

                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: batteryIcon

                text: root.batteryIconName
                color: root.batteryTextColor
                font.family: root.materialFont
                font.pixelSize: root.iconSize
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter

                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: batteryText

                text: batteryReady ? `${batteryPercent}%` : "--%"
                color: root.batteryTextColor
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                verticalAlignment: Text.AlignVCenter

                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: dateText

                text: Qt.formatDateTime(clock.date, "ddd MMM d")
                color: Config.Palette.color("on_surface")
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                verticalAlignment: Text.AlignVCenter

                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: timeText

                text: root.formatTime(clock.date)
                color: Config.Palette.color("on_surface")
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                verticalAlignment: Text.AlignVCenter

                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    MouseArea {
        id: pillHover
        anchors.fill: pill
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: root.updatePopdownHold()
    }

    Timer {
        id: closeTimer
        interval: popdownCloseDelay
        repeat: false
        onTriggered: {
            closeHold = false;
        }
    }

    function updatePopdownTarget() {
        if (!toggleGrid) {
            return;
        }
        const target = Math.round(
            popdownPadding * 2 + toggleGrid.implicitHeight + toggleSpacing + powerMenu.expandedHeight
        );
        popdownTargetHeight = Math.max(popdownMinHeight, target);
    }

    onPopdownOpenChanged: sizeDebounce.restart()

    Timer {
        id: sizeDebounce
        interval: 16
        repeat: false
        onTriggered: updatePopdownTarget()
    }

    PanelWindow {
        id: popdown

        visible: root.popdownOpen || popdownWrapper.implicitHeight > 0
        color: "transparent"
        surfaceFormat.opaque: false
        focusable: false
        exclusiveZone: 0

        anchors.top: true
        anchors.right: true

        margins.top: root.popdownTop
        margins.right: Math.max(0, Math.round(QSWindow.window ? (QSWindow.window.width - (root.pillRect.x + root.pillRect.width)) : 0))

        implicitWidth: popdownWrapper.implicitWidth
        implicitHeight: popdownWrapper.implicitHeight

        mask: Region {
            item: popdownWrapper
        }

        Shared.FrameWrapper {
            id: popdownWrapper

            screen: popdown.screen
            attachEdge: "top-right"
            active: root.popdownOpen
            bubbleColorRole: "surface"
            bubblePadding: 0
            bubbleRounding: root.barCornerRadius

            width: implicitWidth
            height: root.popdownOpen ? Math.round(root.popdownTargetHeight + root.barCornerRadius) : 0
            implicitWidth: root.popdownWidth + root.barCornerRadius
            implicitHeight: root.popdownTargetHeight + root.barCornerRadius
            clip: true
            visible: root.popdownOpen || height > 0

            Behavior on height {
                Anim {
                    durationMs: Config.Motion.shellDuration
                    curve: Config.Motion.shellCurve
                }
            }

            anchors.top: parent.top

            // Height follows implicit size without re-animating content changes.

                Item {
                    id: popdownSurface

                    width: root.popdownWidth + root.barCornerRadius
                    height: root.popdownTargetHeight + root.barCornerRadius
                    anchors.top: parent.top

                    Rectangle {
                        id: popdownBody

                        width: root.popdownWidth
                        height: root.popdownTargetHeight
                        x: root.barCornerRadius
                    radius: root.barCornerRadius
                    color: root.barColor
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.left: popdownBody.left
                    anchors.top: popdownBody.top
                    color: popdownBody.color
                    z: 1
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.right: popdownBody.right
                    anchors.top: popdownBody.top
                    color: popdownBody.color
                    z: 1
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.right: popdownBody.right
                    anchors.bottom: popdownBody.bottom
                    color: popdownBody.color
                    z: 1
                }

                Shared.CornerCutout {
                    id: leftEdgeArc

                    visible: root.barCornerRadius > 0
                    radius: root.barCornerRadius
                    fillColor: popdownBody.color
                    mirrorX: true
                    anchors.right: popdownBody.left
                    anchors.top: popdownBody.top
                }

                Shared.CornerCutout {
                    id: bottomEdgeArc

                    visible: root.barCornerRadius > 0
                    radius: root.barCornerRadius
                    fillColor: popdownBody.color
                    mirrorX: true
                    anchors.right: popdownBody.right
                    anchors.top: popdownBody.bottom
                }

                ColumnLayout {
                    id: quickSettingsLayout

                    anchors.top: parent.top
                    anchors.left: popdownBody.left
                    anchors.right: popdownBody.right
                    anchors.topMargin: root.popdownPadding
                    anchors.leftMargin: root.popdownPadding
                    anchors.rightMargin: root.popdownPadding
                    spacing: root.toggleSpacing
                    z: 2

                    GridLayout {
                        id: toggleGrid

                        columns: 2
                        columnSpacing: root.toggleSpacing
                        rowSpacing: root.toggleSpacing
                        Layout.fillWidth: true

                        Shared.QuickToggle {
                            label: "Wi-Fi"
                            icon: "wifi"
                            iconFont: root.materialFont
                            active: Services.ConnectivityService.wifiEnabled
                            secondaryText: Services.ConnectivityService.wifiConnected
                                ? Services.ConnectivityService.wifiSsid
                                : (Services.ConnectivityService.wifiEnabled ? "Not connected" : "")
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: Services.ConnectivityService.setWifiEnabled(next)
                        }

                        Shared.QuickToggle {
                            label: "Bluetooth"
                            icon: "bluetooth"
                            iconFont: root.materialFont
                            active: Services.ConnectivityService.bluetoothEnabled
                            secondaryText: Services.ConnectivityService.bluetoothDevices !== ""
                                ? Services.ConnectivityService.bluetoothDevices
                                : (Services.ConnectivityService.bluetoothEnabled ? "No devices" : "")
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: Services.ConnectivityService.setBluetoothEnabled(next)
                        }

                        Shared.QuickToggle {
                            label: "Airplane"
                            icon: "airplanemode_active"
                            iconFont: root.materialFont
                            active: Services.ConnectivityService.airplaneEnabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: Services.ConnectivityService.setAirplaneEnabled(next)
                        }

                        Shared.QuickToggle {
                            label: "Do Not Disturb"
                            icon: "notifications_off"
                            iconFont: root.materialFont
                            active: root.dndEnabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: root.dndEnabled = next
                        }

                        Shared.QuickToggle {
                            label: "Night Light"
                            icon: "nightlight"
                            iconFont: root.materialFont
                            active: root.nightLightEnabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: root.nightLightEnabled = next
                        }

                        Shared.QuickToggle {
                            label: "Dark Mode"
                            icon: "dark_mode"
                            iconFont: root.materialFont
                            active: root.darkModeEnabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: root.darkModeEnabled = next
                        }

                    }

                    Shared.PowerMenu {
                        id: powerMenu

                        iconFont: root.materialFont
                        spacing: root.toggleSpacing
                        itemHeight: Math.max(36, Math.round(root.toggleHeight * 0.8))
                        Layout.fillWidth: true
                        onActionTriggered: {
                            if (actionId === "lock") {
                                Services.PowerService.lock();
                                return;
                            }
                            if (actionId === "suspend") {
                                Services.PowerService.suspend();
                                return;
                            }
                            if (actionId === "hibernate") {
                                Services.PowerService.hibernate();
                                return;
                            }
                            if (actionId === "logout") {
                                Services.PowerService.logout();
                                return;
                            }
                            if (actionId === "reboot") {
                                Services.PowerService.reboot();
                                return;
                            }
                            if (actionId === "poweroff") {
                                Services.PowerService.poweroff();
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: popdownHover
                anchors.fill: popdownWrapper
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onContainsMouseChanged: root.updatePopdownHold()
            }
        }
    }

}
