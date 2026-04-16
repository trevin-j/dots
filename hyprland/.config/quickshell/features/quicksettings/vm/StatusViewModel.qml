pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import "../../../config" as Config
import "../../../services" as Services
import "./" as Vm
import "StatusIconLogic.js" as IconLogic

Item {
    id: root

    readonly property bool dndEnabled: Services.NotificationService.dndEnabled
    readonly property bool darkModeEnabled: Services.WallpaperService.darkModeEnabled

    readonly property bool nightLightEnabled: Services.NightLightService.enabled

    Vm.ConnectivityModel {
        id: connectivityModel
    }

    readonly property var connectivity: connectivityModel

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryReady: batteryDevice?.ready ?? false
    readonly property bool hasBattery: IconLogic.hasBattery(
        batteryReady,
        batteryDevice?.isLaptopBattery ?? false,
        batteryDevice?.isPresent
    )
    readonly property real batteryRawPercent: hasBattery ? batteryDevice.percentage : 0
    readonly property int batteryPercent: hasBattery ? Math.round(batteryRawPercent <= 1 ? batteryRawPercent * 100 : batteryRawPercent) : 0
    readonly property bool batteryLow: hasBattery && batteryPercent <= 10
    readonly property bool batteryCharging: hasBattery
        && (batteryDevice.state === UPowerDeviceState.Charging
            || batteryDevice.state === UPowerDeviceState.PendingCharge)

    readonly property string batteryIconName: {
        return IconLogic.batteryIconName(hasBattery, batteryCharging, batteryPercent);
    }

    readonly property color batteryTextColor: batteryLow ? Config.Palette.color("error") : Config.Palette.color("on_surface")
    readonly property string batteryPercentLabel: hasBattery ? `${batteryPercent}%` : ""

    readonly property int wifiStrength: connectivityModel.wifiStrength
    readonly property bool wifiConnected: connectivityModel.wifiConnected
    readonly property bool ethernetConnected: connectivityModel.ethernetConnected

    readonly property string wifiIconName: {
        return IconLogic.wifiIconName(ethernetConnected, wifiConnected, wifiStrength);
    }

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property real volumeLevel: defaultSink?.audio?.volume ?? 0
    readonly property bool volumeMuted: defaultSink?.audio?.muted ?? false

    readonly property string volumeIconName: {
        return IconLogic.volumeIconName(volumeMuted, volumeLevel);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property string dateText: Qt.formatDateTime(clock.date, "ddd MMM d")
    readonly property string timeText: Qt.formatDateTime(clock.date, "h:mm AP")

    function setNightLightEnabled(next) {
        Services.NightLightService.setEnabled(next);
    }

    function setDarkModeEnabled(next) {
        Services.WallpaperService.setDarkModeEnabled(next);
    }

    function setDndEnabled(next) {
        Services.NotificationService.setDndEnabled(next);
    }
}
