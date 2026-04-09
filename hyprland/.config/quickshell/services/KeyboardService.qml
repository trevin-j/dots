pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "parsers/KeyboardParsers.js" as KeyboardParsers

/*
  KeyboardService
  Manages wvkbd-deskintl on-screen keyboard state.
  Signals: SIGUSR2 = show, SIGUSR1 = hide
*/
Scope {
    id: root

    property bool visible: false
    property bool localToggleInFlight: false
    readonly property int localToggleSettleMs: 250

    function refresh() {
        detectProcess.exec(["hyprctl", "-j", "layers"]);
    }

    function show() {
        root.visible = true;
        root.localToggleInFlight = true;
        settleTimer.restart();
        sigProcess.exec(["/bin/sh", "-lc", "pkill -USR2 wvkbd-deskintl || hyprctl dispatch exec \"wvkbd-deskintl --hidden\""]);
        refreshDelay.restart();
    }

    function hide() {
        root.visible = false;
        root.localToggleInFlight = true;
        settleTimer.restart();
        sigProcess.exec(["/bin/sh", "-lc", "pkill -USR1 wvkbd-deskintl"]);
        refreshDelay.restart();
    }

    function toggle() {
        if (root.visible) {
            root.hide();
        } else {
            root.show();
        }
    }

    IpcHandler {
        target: "keyboard"

        function toggle(): void {
            root.toggle();
        }

        function show(): void {
            root.show();
        }

        function hide(): void {
            root.hide();
        }

        function isVisible(): bool {
            return root.visible;
        }
    }

    Process {
        id: sigProcess

        stdout: StdioCollector {
            onStreamFinished: refreshDelay.restart()
        }

        stderr: StdioCollector {
            onStreamFinished: refreshDelay.restart()
        }
    }

    Process {
        id: detectProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const actualVisible = KeyboardParsers.parseLayerState(text, "wvkbd");
                if (!root.localToggleInFlight || actualVisible === root.visible) {
                    root.visible = actualVisible;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {}
        }
    }

    Timer {
        id: refreshDelay

        interval: 120
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: pollingTimer

        interval: 300
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: settleTimer

        interval: root.localToggleSettleMs
        repeat: false
        onTriggered: root.localToggleInFlight = false
    }

    Component.onCompleted: {
        sigProcess.exec(["/bin/sh", "-lc", "pgrep -x wvkbd-deskintl >/dev/null || hyprctl dispatch exec \"wvkbd-deskintl --hidden\""]);
        refreshDelay.restart();
    }
}
