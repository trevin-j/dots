pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*
  WhichKeyService
  Exposes IPC entrypoints for which-key state and executes configured bind commands.
*/
Scope {
    id: root

    property var stateRef: null

    function registerState(state) {
        if (!state) {
            return;
        }
        root.stateRef = state;
    }

    function unregisterState(state) {
        if (root.stateRef === state) {
            root.stateRef = null;
        }
    }

    function withState(callback) {
        if (!root.stateRef) {
            return;
        }
        callback(root.stateRef);
    }

    function toggleLeader() {
        root.withState(state => state.toggleLeader());
    }

    function close() {
        root.withState(state => state.close());
    }

    function isOpen() {
        if (!root.stateRef) {
            return false;
        }
        return !!root.stateRef.open;
    }

    function executeCommand(command) {
        const normalized = typeof command === "string" ? command.trim() : "";
        if (!normalized) {
            return;
        }
        commandProcess.exec(["/bin/sh", "-lc", normalized]);
    }

    IpcHandler {
        target: "whichkey"

        function toggleLeader(): void {
            root.toggleLeader();
        }

        function close(): void {
            root.close();
        }

        function isOpen(): bool {
            return root.isOpen();
        }
    }

    Process {
        id: commandProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("WhichKeyService command failed", output);
                }
            }
        }
    }
}
