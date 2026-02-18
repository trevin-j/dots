pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

Item {
    id: root

    required property ShellScreen screen

    readonly property var activeMonitor: Hyprland.monitorFor(root.screen)
    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property var activeWorkspace: activeMonitor?.activeWorkspace || Hyprland.focusedWorkspace

    readonly property var resolvedToplevel: {
        if (!activeToplevel) {
            return null;
        }
        if (activeMonitor && activeToplevel.monitor && activeToplevel.monitor !== activeMonitor) {
            return null;
        }
        return activeToplevel;
    }

    readonly property int activeWorkspaceWindowCount: activeWorkspace?.toplevels?.values?.length ?? activeWorkspace?.lastIpcObject?.windows ?? 0

    readonly property bool hasActiveWindow: resolvedToplevel !== null
        && resolvedToplevel.title !== ""
        && resolvedToplevel.title !== undefined
        && activeWorkspace
        && resolvedToplevel.workspace === activeWorkspace
        && activeWorkspaceWindowCount > 0

    readonly property var resolvedEntry: {
        if (!resolvedToplevel) {
            return null;
        }
        const ipc = resolvedToplevel.lastIpcObject || {};
        const candidates = [ipc.class, ipc.initialClass, ipc.appid, ipc.appId, resolvedToplevel.title];
        for (const candidate of candidates) {
            if (!candidate) {
                continue;
            }
            const entry = DesktopEntries.heuristicLookup(candidate);
            if (entry) {
                return entry;
            }
        }
        return null;
    }

    readonly property string displayName: resolvedToplevel?.title || ""
    readonly property string iconName: resolvedEntry?.icon || ""
    readonly property string iconSource: iconName ? Quickshell.iconPath(iconName, true) : ""

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "moveworkspace" || event.name === "openwindow" || event.name === "closewindow" || event.name === "movewindow" || event.name === "focusedmon") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
            }
        }
    }
}
