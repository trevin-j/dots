pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "parsers/BrightnessParsers.js" as BrightnessParsers

/*!
  BrightnessService
  Manages brightness via brightnessctl and exposes level (0-1).
*/
Scope {
    id: root

    property real level: 0
    property bool ready: false
    property bool applyInFlight: false
    property string lastError: ""

    readonly property string brightnessctlPath: "/usr/bin/brightnessctl"
    readonly property string configuredDevice: Config.Config.popouts?.brightness?.device ?? ""
    readonly property bool deviceLocked: configuredDevice !== ""

    property string deviceName: configuredDevice

    function clampLevel(value) {
        return BrightnessParsers.clampLevel(value);
    }

    function buildCommand(args) {
        const command = [root.brightnessctlPath];
        if (root.deviceName) {
            command.push("-d", root.deviceName);
        }
        return command.concat(args);
    }

    function setLevel(value) {
        const clamped = clampLevel(value);
        const percent = Math.round(clamped * 100);
        root.level = clamped;
        root.applyInFlight = true;
        root.lastError = "";
        setProcess.exec(root.buildCommand(["set", `${percent}%`]));
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
                const parsed = BrightnessParsers.parseBrightnessctlOutput(output);
                if (!parsed.ok) {
                    root.lastError = `BrightnessService: ${parsed.error}`;
                    return;
                }
                if (!root.deviceLocked && !root.deviceName && parsed.deviceName) {
                    root.deviceName = parsed.deviceName;
                }
                root.level = parsed.level;
                root.ready = true;
                root.lastError = "";
            }
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
        id: setProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.applyInFlight = false;
                root.refresh();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                root.applyInFlight = false;
                if (output) {
                    root.lastError = output;
                }
                root.refresh();
            }
        }
    }

    Component.onCompleted: refresh()

    onDeviceNameChanged: {
        if (ready) {
            refresh();
        }
    }
}
