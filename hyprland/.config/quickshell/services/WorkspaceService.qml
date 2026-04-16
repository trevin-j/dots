pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import "./" as Services

/*
  WorkspaceService
  Manages workspace operations and exposes IPC controls for the rename panel.
*/
Scope {
    id: root

    readonly property string panelId: "workspacerename"
    property var entries: []

    property int currentWorkspaceId: Hyprland.focusedWorkspace?.id ?? -1
    property string currentWorkspaceName: Hyprland.focusedWorkspace?.name ?? ""

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

    function openRenamePanel() {
        root.refreshCurrentWorkspace();
        Services.WhichKeyService.close();
        root.withTargetState(state => state.open = true);
    }

    function closeRenamePanel() {
        root.withTargetState(state => state.open = false);
    }

    function closeAll() {
        for (const entry of root.entries) {
            if (entry && entry.state) {
                entry.state.open = false;
            }
        }
    }

    function refreshCurrentWorkspace() {
        root.currentWorkspaceId = Hyprland.focusedWorkspace?.id ?? -1;
        root.currentWorkspaceName = Hyprland.focusedWorkspace?.name ?? "";
    }

    function renameWorkspace(id, name) {
        if (id < 0) {
            return;
        }

        const safeName = typeof name === "string" ? name : "";
        renameProcess.exec(["/bin/sh", "-lc", `hyprctl dispatch renameworkspace ${id} "${safeName}"`]);
    }

    function activateWorkspace(id) {
        if (id < 0) {
            return;
        }

        activateProcess.exec(["hyprctl", "dispatch", "workspace", id.toString()]);
    }

    IpcHandler {
        target: "workspace"

        function openRenamePanel(): void {
            root.openRenamePanel();
        }

        function closeRenamePanel(): void {
            root.closeRenamePanel();
        }

        function renameWorkspace(id, name): void {
            root.renameWorkspace(id, name);
        }

        function activateWorkspace(id): void {
            root.activateWorkspace(id);
        }
    }

    Process {
        id: renameProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("WorkspaceService rename failed", output);
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
                    console.warn("WorkspaceService activate failed", output);
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            root.refreshCurrentWorkspace();
        }
    }

    Component.onCompleted: Services.PanelExclusivityService.registerPanel(root.panelId, root)
    Component.onDestruction: Services.PanelExclusivityService.unregisterPanel(root.panelId, root)
}
