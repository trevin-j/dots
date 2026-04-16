pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import "./" as Services
import "../features/clipboardhistory/vm/ClipboardHistoryLogic.js" as ClipboardHistoryLogic

/*
  ClipboardHistoryService
  Tracks per-screen clipboard history panel state and activates cliphist entries.
 */
Scope {
    id: root

    readonly property string panelId: "clipboardhistory"
    property var entries: []
    property var historyEntries: []

    function shellQuote(value) {
        const text = typeof value === "string" ? value : "";
        return `'${text.replace(/'/g, `'"'"'`)}'`;
    }

    function monitorKey(monitor) {
        if (!monitor) {
            return "";
        }

        return monitor.name
            || monitor.connector
            || monitor.id
            || monitor.lastIpcObject?.name
            || "";
    }

    function focusedMonitorKey() {
        return root.monitorKey(Hyprland.focusedMonitor);
    }

    function stateEntryForFocusedMonitor() {
        const key = root.focusedMonitorKey();
        if (key === "") {
            return null;
        }

        for (const entry of root.entries) {
            if (!entry || !entry.screen || !entry.state) {
                continue;
            }

            const monitor = Hyprland.monitorFor(entry.screen);
            if (root.monitorKey(monitor) === key) {
                return entry;
            }
        }

        return null;
    }

    function fallbackEntry() {
        for (const entry of root.entries) {
            if (entry && entry.state) {
                return entry;
            }
        }

        return null;
    }

    function withTargetState(callback) {
        const entry = root.stateEntryForFocusedMonitor() || root.fallbackEntry();
        if (!entry || !entry.state) {
            return;
        }

        callback(entry.state);
    }

    function targetState() {
        const entry = root.stateEntryForFocusedMonitor() || root.fallbackEntry();
        if (!entry || !entry.state) {
            return null;
        }

        return entry.state;
    }

    function registerScreenState(screen, state) {
        if (!screen || !state) {
            return;
        }

        const filtered = root.entries.filter(entry => entry && entry.state && entry.state !== state);
        filtered.push({
            screen: screen,
            state: state
        });
        root.entries = filtered;
    }

    function unregisterScreenState(state) {
        if (!state) {
            return;
        }

        root.entries = root.entries.filter(entry => entry && entry.state && entry.state !== state);
    }

    function toggle() {
        if (root.isTargetOpen()) {
            root.close();
            return;
        }

        root.open();
    }

    function open() {
        const state = root.targetState();
        if (!state) {
            return;
        }

        Services.PanelExclusivityService.requestOpen(root.panelId);
        root.closeAll();
        root.refreshHistory();
        state.openPanel();
    }

    function close() {
        root.withTargetState(state => state.close());
    }

    function closeAll() {
        for (const entry of root.entries) {
            if (entry?.state) {
                entry.state.close();
            }
        }
    }

    function isOpen() {
        for (const entry of root.entries) {
            if (entry?.state?.open) {
                return true;
            }
        }

        return false;
    }

    function isTargetOpen() {
        const state = root.targetState();
        return state ? state.open : false;
    }

    function refreshHistory() {
        listProcess.exec(["cliphist", "list"]);
    }

    function activateEntry(rawValue) {
        const value = typeof rawValue === "string" ? rawValue : "";
        if (!value) {
            return;
        }

        activateProcess.exec([
            "/bin/sh",
            "-lc",
            `cliphist decode ${root.shellQuote(value)} | sed -z 's/\\n$//' | wtype -`
        ]);
    }

    Process {
        id: listProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.historyEntries = ClipboardHistoryLogic.parseListText(text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("ClipboardHistoryService list failed", output);
                }
            }
        }
    }

    Process {
        id: activateProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("ClipboardHistoryService activate failed", output);
                }
            }
        }
    }

    IpcHandler {
        target: "clipboardhistory"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function refresh(): void {
            root.refreshHistory();
        }

        function isOpen(): bool {
            return root.isOpen();
        }
    }

    Component.onCompleted: Services.PanelExclusivityService.registerPanel(root.panelId, root)
    Component.onDestruction: Services.PanelExclusivityService.unregisterPanel(root.panelId, root)
}
