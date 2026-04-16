function hasBattery(batteryReady, isLaptopBattery, isPresent) {
    return batteryReady && isLaptopBattery && (isPresent === undefined || isPresent);
}

function batteryIconName(batteryReady, batteryCharging, batteryPercent) {
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

function wifiIconName(ethernetConnected, wifiConnected, wifiStrength) {
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

function volumeIconName(volumeMuted, volumeLevel) {
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
