pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config

/*!
  BrightnessService
  Manages brightness via brightnessctl and exposes level (0-1).
*/
Scope {
    id: root

    property real level: 0
    property bool ready: false

    readonly property string brightnessctlPath: "/usr/bin/brightnessctl"
    readonly property string configuredDevice: Config.Config.popouts?.brightness?.device ?? ""
    readonly property bool deviceLocked: configuredDevice !== ""

    property string deviceName: configuredDevice

    function buildCommand(args) {
        const command = [root.brightnessctlPath];
        if (root.deviceName) {
            command.push("-d", root.deviceName);
        }
        return command.concat(args);
    }

    function setLevel(value) {
        const clamped = Math.max(0, Math.min(1, value));
        root.level = clamped;
        root.ready = true;
    }

    function refresh() {
        getProcess.exec(root.buildCommand(["-m"]));
    }

    IpcHandler {
        target: "brightness"

        function setLevel(value: int): void {
            root.setLevel(value / 100);
        }

        function refresh(): void {
            root.refresh();
        }
    }

    Process {
        id: getProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!output) {
                    return;
                }
                const parts = output.split(",");
                if (parts.length < 4) {
                    return;
                }
                if (!root.deviceLocked && !root.deviceName && parts[0]) {
                    root.deviceName = parts[0];
                }
                const percentValue = Number(parts[3].replace("%", ""));
                if (Number.isNaN(percentValue)) {
                    return;
                }
                root.level = Math.max(0, Math.min(1, percentValue / 100));
                root.ready = true;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    root.ready = false;
                }
            }
        }
    }
}
