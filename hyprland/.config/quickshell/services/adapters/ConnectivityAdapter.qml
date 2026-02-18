pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*
  ConnectivityAdapter
  Executes network and bluetooth commands and exposes raw command outputs.
*/
Scope {
    id: root

    readonly property string nmcliPath: "/usr/bin/nmcli"
    readonly property string bluetoothctlPath: "/usr/bin/bluetoothctl"

    property string wifiScanOutput: ""
    property string deviceStateOutput: ""
    property string activeConnectionOutput: ""
    property string wifiRadioOutput: ""
    property string allRadioOutput: ""
    property string bluetoothShowOutput: ""
    property string bluetoothDevicesOutput: ""

    property bool suppressAirplaneUpdate: false
    property string lastError: ""

    function refresh() {
        wifiScanProcess.exec([nmcliPath, "-t", "-f", "IN-USE,SIGNAL,DEVICE", "dev", "wifi"]);
        deviceStateProcess.exec([nmcliPath, "-t", "-f", "TYPE,STATE", "dev"]);
        activeConnectionProcess.exec([nmcliPath, "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]);
        wifiRadioProcess.exec([nmcliPath, "-t", "-f", "WIFI", "radio"]);
        allRadioProcess.exec([nmcliPath, "-t", "-f", "ALL", "radio"]);
        bluetoothShowProcess.exec([bluetoothctlPath, "show"]);
        bluetoothDevicesProcess.exec([bluetoothctlPath, "devices", "Connected"]);
    }

    function setWifiEnabled(enabled) {
        wifiToggleProcess.exec([nmcliPath, "radio", "wifi", enabled ? "on" : "off"]);
        refreshSoon();
    }

    function setBluetoothEnabled(enabled) {
        bluetoothToggleProcess.exec([bluetoothctlPath, "power", enabled ? "on" : "off"]);
        refreshSoon();
    }

    function setAirplaneEnabled(enabled) {
        suppressAirplaneUpdate = true;
        airplaneToggleProcess.exec([nmcliPath, "radio", "all", enabled ? "off" : "on"]);
        bluetoothToggleProcess.exec([bluetoothctlPath, "power", enabled ? "off" : "on"]);
        refreshSoon();
    }

    function refreshSoon() {
        delayedRefresh.restart();
    }

    Timer {
        id: pollTimer
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: delayedRefresh
        interval: 500
        repeat: false
        onTriggered: {
            root.suppressAirplaneUpdate = false;
            root.refresh();
        }
    }

    Process {
        id: wifiScanProcess

        stdout: StdioCollector {
            onStreamFinished: root.wifiScanOutput = text.trim()
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    root.lastError = output;
                }
            }
        }
    }

    Process {
        id: deviceStateProcess

        stdout: StdioCollector {
            onStreamFinished: root.deviceStateOutput = text.trim()
        }
    }

    Process {
        id: activeConnectionProcess

        stdout: StdioCollector {
            onStreamFinished: root.activeConnectionOutput = text.trim()
        }
    }

    Process {
        id: wifiRadioProcess

        stdout: StdioCollector {
            onStreamFinished: root.wifiRadioOutput = text.trim()
        }
    }

    Process {
        id: allRadioProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.suppressAirplaneUpdate) {
                    root.allRadioOutput = text.trim();
                }
            }
        }
    }

    Process {
        id: bluetoothShowProcess

        stdout: StdioCollector {
            onStreamFinished: root.bluetoothShowOutput = text
        }
    }

    Process {
        id: bluetoothDevicesProcess

        stdout: StdioCollector {
            onStreamFinished: root.bluetoothDevicesOutput = text.trim()
        }
    }

    Process { id: wifiToggleProcess }
    Process { id: bluetoothToggleProcess }
    Process { id: airplaneToggleProcess }
}
