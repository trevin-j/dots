import QtQuick
import QtTest

import "../../../features/quicksettings/vm/StatusIconLogic.js" as IconLogic

TestCase {
    name: "StatusIconLogic"

    function test_wifiIconLogic() {
        compare(IconLogic.wifiIconName(true, false, 0), "settings_ethernet");
        compare(IconLogic.wifiIconName(false, false, 0), "wifi_off");
        compare(IconLogic.wifiIconName(false, true, 80), "wifi");
        compare(IconLogic.wifiIconName(false, true, 50), "wifi_2_bar");
        compare(IconLogic.wifiIconName(false, true, 20), "wifi_1_bar");
    }

    function test_volumeIconLogic() {
        compare(IconLogic.volumeIconName(true, 0.7), "volume_off");
        compare(IconLogic.volumeIconName(false, 0), "volume_off");
        compare(IconLogic.volumeIconName(false, 0.2), "volume_mute");
        compare(IconLogic.volumeIconName(false, 0.5), "volume_down");
        compare(IconLogic.volumeIconName(false, 0.9), "volume_up");
    }

    function test_batteryIconLogic() {
        verify(!IconLogic.hasBattery(false, false, undefined));
        verify(!IconLogic.hasBattery(true, false, undefined));
        verify(!IconLogic.hasBattery(true, true, false));
        verify(IconLogic.hasBattery(true, true, true));
        verify(IconLogic.hasBattery(true, true, undefined));

        compare(IconLogic.batteryIconName(false, false, 10), "battery_unknown");
        compare(IconLogic.batteryIconName(true, true, 50), "battery_charging_full");
        compare(IconLogic.batteryIconName(true, false, 96), "battery_full");
        compare(IconLogic.batteryIconName(true, false, 12), "battery_1_bar");
        compare(IconLogic.batteryIconName(true, false, 5), "battery_0_bar");
    }
}
