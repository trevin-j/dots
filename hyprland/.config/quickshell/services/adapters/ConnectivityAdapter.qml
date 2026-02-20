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
    readonly property string busctlPath: "/usr/bin/busctl"
    readonly property string bluezService: "org.bluez"
    readonly property string bluetoothAdapterPath: "/org/bluez/hci0"

    property string wifiScanOutput: ""
    property string deviceStateOutput: ""
    property string activeConnectionOutput: ""
    property string wifiRadioOutput: ""
    property string bluetoothStateOutput: ""
    property string allRadioOutput: ""
    property string bluetoothDevicesOutput: ""

    property bool suppressAirplaneUpdate: false
    property string lastError: ""

    function sanitizeOutput(output) {
        if (!output) {
            return "";
        }

        return output
            .replace(/\u001b\[[0-9;?]*[ -/]*[@-~]/g, "")
            .replace(/\r/g, "")
            .trim();
    }

    function bluetoothConnectedDevicesCommand() {
        return "/usr/bin/busctl --system tree org.bluez | while read -r line; do dev=${line##* }; case \"$dev\" in /org/bluez/hci0/dev_??_??_??_??_??_??) connected=$(/usr/bin/busctl --system get-property org.bluez \"$dev\" org.bluez.Device1 Connected 2>/dev/null | tr -d '\\r'); if [ \"$connected\" = \"b true\" ]; then alias=$(/usr/bin/busctl --system get-property org.bluez \"$dev\" org.bluez.Device1 Alias 2>/dev/null | awk -F'\"' '{print $2}'); if [ -z \"$alias\" ]; then alias=$(/usr/bin/busctl --system get-property org.bluez \"$dev\" org.bluez.Device1 Name 2>/dev/null | awk -F'\"' '{print $2}'); fi; if [ -n \"$alias\" ]; then printf '%s\\n' \"$alias\"; fi; fi ;; esac; done";
    }

    function refresh() {
        wifiScanProcess.exec([nmcliPath, "-t", "-f", "IN-USE,SIGNAL,DEVICE", "dev", "wifi"]);
        deviceStateProcess.exec([nmcliPath, "-t", "-f", "TYPE,STATE", "dev"]);
        activeConnectionProcess.exec([nmcliPath, "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]);
        wifiRadioProcess.exec([nmcliPath, "-t", "-f", "WIFI", "radio"]);
        bluetoothStateProcess.exec([busctlPath, "--system", "get-property", bluezService, bluetoothAdapterPath, "org.bluez.Adapter1", "Powered"]);
        allRadioProcess.exec([nmcliPath, "-t", "-f", "ALL", "radio"]);
        bluetoothDevicesProcess.exec(["/bin/sh", "-lc", bluetoothConnectedDevicesCommand()]);
    }

    function setWifiEnabled(enabled) {
        wifiToggleProcess.exec([nmcliPath, "radio", "wifi", enabled ? "on" : "off"]);
        refreshSoon();
    }

    function setBluetoothEnabled(enabled) {
        bluetoothToggleProcess.exec([busctlPath, "--system", "set-property", bluezService, bluetoothAdapterPath, "org.bluez.Adapter1", "Powered", "b", enabled ? "true" : "false"]);
        refreshSoon();
    }

    function setAirplaneEnabled(enabled) {
        suppressAirplaneUpdate = true;
        airplaneToggleProcess.exec([nmcliPath, "radio", "all", enabled ? "off" : "on"]);
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
        id: bluetoothStateProcess

        stdout: StdioCollector {
            onStreamFinished: root.bluetoothStateOutput = root.sanitizeOutput(text)
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
        id: bluetoothDevicesProcess

        stdout: StdioCollector {
            onStreamFinished: root.bluetoothDevicesOutput = root.sanitizeOutput(text)
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

    Process { id: wifiToggleProcess }
    Process {
        id: bluetoothToggleProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = root.sanitizeOutput(text);
                if (output) {
                    root.lastError = output;
                }
            }
        }
    }
    Process { id: airplaneToggleProcess }
}
