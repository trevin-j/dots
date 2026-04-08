pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*
  KeyboardService
  Manages wvkbd-deskintl on-screen keyboard state.
  Signals: SIGUSR2 = show, SIGUSR1 = hide
*/
Scope {
    id: root

    property bool visible: false

    function show() {
        root.visible = true;
        sigProcess.exec(["/bin/sh", "-lc", "pkill -USR2 wvkbd-deskintl || hyprctl dispatch exec \"wvkbd-deskintl --hidden\""]);
    }

    function hide() {
        root.visible = false;
        sigProcess.exec(["/bin/sh", "-lc", "pkill -USR1 wvkbd-deskintl"]);
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
    }

    Component.onCompleted: {
        sigProcess.exec(["/bin/sh", "-lc", "pgrep -x wvkbd-deskintl >/dev/null || hyprctl dispatch exec \"wvkbd-deskintl --hidden\""]);
    }
}
