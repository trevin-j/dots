pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property ShellScreen screen

    readonly property var activeMonitor: Hyprland.monitorFor(root.screen)
    readonly property string activeMonitorName: activeMonitor?.name ?? ""
    readonly property int activeWorkspaceId: activeMonitor?.activeWorkspace?.id ?? -1

    property var liveWorkspaces: []

    function isSpecialWorkspace(workspace) {
        return !!workspace && workspace.name && workspace.name.startsWith("special");
    }

    function isNamedWorkspace(workspace) {
        return !!workspace && workspace.name && workspace.name !== workspace.id.toString();
    }

    function workspaceLabel(workspace) {
        if (!workspace) {
            return "";
        }
        if (workspace.name && workspace.name !== workspace.id.toString()) {
            return workspace.id.toString() + ": " + workspace.name;
        }
        return workspace.id.toString();
    }

    function refreshWorkspaces() {
        const focusedId = Hyprland.focusedWorkspace?.id;
        const monitorName = root.activeMonitorName;
        root.liveWorkspaces = Hyprland.workspaces.values.filter(workspace => {
            const windows = workspace.lastIpcObject?.windows ?? 0;
            const isFocused = focusedId !== undefined && workspace.id === focusedId;
            const workspaceMonitorName = workspace.monitor?.name ?? "";
            const matchesMonitor = !monitorName || monitorName === workspaceMonitorName;
            return matchesMonitor
                && !isSpecialWorkspace(workspace)
                && (windows > 0 || isFocused || isNamedWorkspace(workspace));
        });
    }

    function refreshAfterEvent(eventName) {
        if (eventName === "workspace" || eventName === "moveworkspace" || eventName === "openwindow" || eventName === "closewindow" || eventName === "movewindow") {
            Hyprland.refreshWorkspaces();
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            root.refreshAfterEvent(event.name);
            root.refreshWorkspaces();
        }
    }

    Connections {
        target: Hyprland.workspaces

        function onValuesChanged() {
            root.refreshWorkspaces();
        }
    }

    Component.onCompleted: refreshWorkspaces()
}
