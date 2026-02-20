import QtQuick
import QtTest

import "../../../features/quicksettings/vm/ConnectivityParsers.js" as Parsers

TestCase {
    name: "ConnectivityParsers"

    function test_wifiStateParsers() {
        verify(Parsers.parseWifiEnabled("enabled"));
        verify(!Parsers.parseWifiEnabled("disabled"));

        const stats = Parsers.parseWifiStats("*:72:wlan0\n:20:wlan1");
        verify(stats.connected);
        compare(stats.strength, 72);

        verify(Parsers.parseEthernetConnected("ethernet:connected\nwifi:disconnected"));
        verify(!Parsers.parseEthernetConnected("wifi:connected"));
    }

    function test_wifiAndBluetoothMetadataParsers() {
        compare(Parsers.parseWifiSsid("Home:wifi:wlan0", true), "Home");
        compare(Parsers.parseWifiSsid("Home:wifi:wlan0", false), "");

        verify(Parsers.parseBluetoothEnabled("enabled"));
        verify(Parsers.parseBluetoothEnabled("BLUETOOTH:enabled"));
        verify(Parsers.parseBluetoothEnabled("b true"));
        verify(Parsers.parseBluetoothEnabled("Controller AA:BB:CC:DD:EE:FF\n\tPowered: yes"));
        verify(Parsers.parseBluetoothEnabled("\u001b[1;39mController AA:BB:CC:DD:EE:FF\u001b[0m\n\u001b[0;92m\tPowered: yes\u001b[0m"));
        verify(!Parsers.parseBluetoothEnabled("disabled"));
        verify(!Parsers.parseBluetoothEnabled("b false"));
        verify(!Parsers.parseBluetoothEnabled("Controller AA:BB:CC:DD:EE:FF\n\tPowered: no"));

        const devices = Parsers.parseBluetoothDevices("Device 11:22:33:44 Headphones\nDevice 99:AA:BB:CC Keyboard", true);
        compare(devices, "Headphones, Keyboard");

        const ansiDevices = Parsers.parseBluetoothDevices("\u001b[0;94mDevice 11:22:33:44 Headphones\u001b[0m\n\u001b[0;94mDevice 99:AA:BB:CC Keyboard\u001b[0m", true);
        compare(ansiDevices, "Headphones, Keyboard");

        const dbusDevices = Parsers.parseBluetoothDevices("MX Master 2S\nCorneWireless", true);
        compare(dbusDevices, "MX Master 2S, CorneWireless");
    }

    function test_airplaneParser() {
        verify(Parsers.parseAirplaneEnabled("disabled"));
        verify(!Parsers.parseAirplaneEnabled("enabled"));
    }
}
