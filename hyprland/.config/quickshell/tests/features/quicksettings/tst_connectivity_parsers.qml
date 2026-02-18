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

        verify(Parsers.parseBluetoothEnabled("Name: adapter\nPowered: yes\n"));
        verify(!Parsers.parseBluetoothEnabled("Powered: no\n"));

        const devices = Parsers.parseBluetoothDevices("Device 11:22:33:44 Headphones\nDevice 99:AA:BB:CC Keyboard", true);
        compare(devices, "Headphones, Keyboard");
    }

    function test_airplaneParser() {
        verify(Parsers.parseAirplaneEnabled("disabled"));
        verify(!Parsers.parseAirplaneEnabled("enabled"));
    }
}
