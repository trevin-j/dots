pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*!
  ConnectivityService
  Tracks Wi-Fi, Bluetooth, and airplane mode state and exposes toggles.
*/
Scope {
    id: root

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property int wifiStrength: -1
    property bool ethernetConnected: false
    property string wifiSsid: ""

    property bool bluetoothEnabled: false
    property bool airplaneEnabled: false
    property string bluetoothDevices: ""
    property bool suppressAirplaneUpdate: false

    readonly property string nmcliPath: "/usr/bin/nmcli"
    readonly property string bluetoothctlPath: "/usr/bin/bluetoothctl"

    function refresh() {
        wifiProcess.exec(["sh", "-c", nmcliPath + " -t -f IN-USE,SIGNAL,DEVICE dev wifi; " + nmcliPath + " -t -f TYPE,STATE dev"]);
        wifiSsidProcess.exec(["sh", "-c", nmcliPath + " -t -f NAME,TYPE,DEVICE connection show --active"]);
        wifiDeviceProcess.exec(["sh", "-c", nmcliPath + " -t -f DEVICE,TYPE,STATE device | awk -F: '$2==\"wifi\" || $2==\"802-11-wireless\" {print $1; exit}' | xargs -I{} " + nmcliPath + " -t -f GENERAL.CONNECTION device show {} | awk -F: '{print $2; exit}'"]);
        wifiRadioProcess.exec(["sh", "-c", nmcliPath + " -t -f WIFI radio"]);
        radioProcess.exec(["sh", "-c", nmcliPath + " -t -f ALL radio"]);
        bluetoothProcess.exec([bluetoothctlPath, "show"]);
        bluetoothDevicesProcess.exec(["sh", "-c", bluetoothctlPath + " devices Connected | sed 's/^Device [^ ]* //'" ]);
    }

    function setWifiEnabled(enabled) {
        if (enabled && root.airplaneEnabled) {
            root.airplaneEnabled = false;
        }
        wifiToggleProcess.exec([nmcliPath, "radio", "wifi", enabled ? "on" : "off"]);
        refreshTimer.restart();
        toggleRefresh.restart();
    }

    function setBluetoothEnabled(enabled) {
        if (enabled && root.airplaneEnabled) {
            root.airplaneEnabled = false;
        }
        bluetoothToggleProcess.exec([bluetoothctlPath, "power", enabled ? "on" : "off"]);
        refreshTimer.restart();
        toggleRefresh.restart();
    }

    function setAirplaneEnabled(enabled) {
        root.airplaneEnabled = enabled;
        root.suppressAirplaneUpdate = true;
        airplaneToggleProcess.exec([nmcliPath, "radio", "all", enabled ? "off" : "on"]);
        bluetoothToggleProcess.exec([bluetoothctlPath, "power", enabled ? "off" : "on"]);
        refreshTimer.restart();
        toggleRefresh.restart();
    }

    Timer {
        id: refreshTimer
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: toggleRefresh
        interval: 500
        repeat: false
        onTriggered: {
            root.suppressAirplaneUpdate = false;
            root.refresh();
        }
    }

    Process {
        id: wifiProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!output) {
                    root.wifiStrength = -1;
                    root.wifiConnected = false;
                    root.ethernetConnected = false;
                    return;
                }
                const lines = output.split("\n");
                let wifiStrength = -1;
                let wifiConnected = false;
                let ethernetConnected = false;
                for (const line of lines) {
                    if (!line) {
                        continue;
                    }
                    const parts = line.split(":");
                    if (parts.length === 3) {
                        const inUse = parts[0];
                        const signalValue = Number(parts[1]);
                        if (inUse === "*") {
                            wifiConnected = true;
                            if (!Number.isNaN(signalValue)) {
                                wifiStrength = Math.max(0, Math.min(100, signalValue));
                            }
                        }
                        continue;
                    }
                    if (parts.length === 2) {
                        const typeValue = parts[0];
                        const stateValue = parts[1];
                        if (typeValue === "ethernet" && stateValue === "connected") {
                            ethernetConnected = true;
                        }
                    }
                }
                root.wifiStrength = wifiStrength;
                root.wifiConnected = wifiConnected;
                root.ethernetConnected = ethernetConnected;
            }
        }
    }

    Process {
        id: wifiSsidProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.wifiEnabled) {
                    root.wifiSsid = "";
                    return;
                }
                const output = text.trim();
                if (!output) {
                    root.wifiSsid = "";
                    return;
                }
                const lines = output.split("\n");
                for (const line of lines) {
                    if (!line) {
                        continue;
                    }
                    const parts = line.split(":");
                    if (parts.length >= 3 && (parts[1] === "wifi" || parts[1] === "802-11-wireless")) {
                        root.wifiSsid = parts[0];
                        return;
                    }
                }
                root.wifiSsid = "";
            }
        }
    }

    Process {
        id: wifiDeviceProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.wifiEnabled || root.wifiSsid) {
                    return;
                }
                const output = text.trim();
                if (!output) {
                    return;
                }
                root.wifiSsid = output;
            }
        }
    }

    Process {
        id: wifiRadioProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!output) {
                    return;
                }
                const value = output.includes(":") ? output.split(":").pop() : output;
                root.wifiEnabled = value.trim() === "enabled";
            }
        }
    }

    Process {
        id: radioProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.suppressAirplaneUpdate) {
                    return;
                }
                const output = text.trim();
                if (!output) {
                    return;
                }
                const value = output.includes(":") ? output.split(":").pop() : output;
                root.airplaneEnabled = value.trim() === "disabled";
            }
        }
    }

    Process {
        id: bluetoothProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                for (const line of lines) {
                    const trimmed = line.trim();
                    if (trimmed.startsWith("Powered:")) {
                        root.bluetoothEnabled = trimmed.toLowerCase().endsWith("yes");
                        if (root.bluetoothEnabled) {
                            root.airplaneEnabled = false;
                        }
                        return;
                    }
                }
            }
        }
    }

    Process {
        id: bluetoothDevicesProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!root.bluetoothEnabled) {
                    root.bluetoothDevices = "";
                    return;
                }
                root.bluetoothDevices = output ? output.replace(/\n+/g, ", ") : "";
            }
        }
    }

    Process { id: wifiToggleProcess }
    Process { id: bluetoothToggleProcess }
    Process { id: airplaneToggleProcess }
}
