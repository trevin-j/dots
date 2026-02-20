pragma ComponentBehavior: Bound

import QtQuick

import "../../../services" as Services
import "ConnectivityParsers.js" as Parsers

QtObject {
    id: root

    readonly property var adapter: Services.ConnectivityAdapter

    readonly property bool wifiEnabled: Parsers.parseWifiEnabled(adapter.wifiRadioOutput)

    readonly property var wifiStats: Parsers.parseWifiStats(adapter.wifiScanOutput)

    readonly property bool wifiConnected: wifiStats.connected
    readonly property int wifiStrength: wifiStats.strength

    readonly property bool ethernetConnected: Parsers.parseEthernetConnected(adapter.deviceStateOutput)

    readonly property string wifiSsid: Parsers.parseWifiSsid(adapter.activeConnectionOutput, wifiEnabled)

    readonly property bool bluetoothEnabled: Parsers.parseBluetoothEnabled(adapter.bluetoothStateOutput)

    readonly property string bluetoothDevices: Parsers.parseBluetoothDevices(adapter.bluetoothDevicesOutput, bluetoothEnabled)

    readonly property bool airplaneEnabled: Parsers.parseAirplaneEnabled(adapter.allRadioOutput)

    readonly property string lastError: adapter.lastError

    function setWifiEnabled(enabled) {
        adapter.setWifiEnabled(enabled);
    }

    function setBluetoothEnabled(enabled) {
        adapter.setBluetoothEnabled(enabled);
    }

    function setAirplaneEnabled(enabled) {
        adapter.setAirplaneEnabled(enabled);
    }

    function refresh() {
        adapter.refresh();
    }
}
