pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "parsers/NightLightParsers.js" as NightLightParsers

/*
  NightLightService
  Controls hyprsunset process state for quick settings night light toggle.
*/
Scope {
    id: root

    property bool enabled: false
    property bool ready: false
    property bool applyInFlight: false
    property string lastError: ""

    readonly property int configuredTemperature: Config.Config.controlCenter?.nightLight?.temperature ?? 3500
    readonly property int temperature: NightLightParsers.clampTemperature(configuredTemperature)

    function refresh() {
        detectProcess.exec(["/bin/sh", "-lc", "pgrep -x hyprsunset || true"]);
    }

    function setEnabled(next) {
        const desired = !!next;
        root.applyInFlight = true;
        root.lastError = "";

        if (desired) {
            applyProcess.exec([
                "/bin/sh",
                "-lc",
                `pkill -x hyprsunset >/dev/null 2>&1 || true; hyprsunset -t ${root.temperature} >/dev/null 2>&1 &`
            ]);
        } else {
            applyProcess.exec(["/bin/sh", "-lc", "pkill -x hyprsunset >/dev/null 2>&1 || true"]);
        }
    }

    Process {
        id: detectProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = NightLightParsers.parsePgrepOutput(text);
                root.ready = true;
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
        id: applyProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.applyInFlight = false;
                refreshDelay.restart();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                root.applyInFlight = false;
                if (output) {
                    root.lastError = output;
                }
                refreshDelay.restart();
            }
        }
    }

    Timer {
        id: refreshDelay

        interval: 120
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
