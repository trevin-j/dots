import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import "./"

Item {
    id: root

    required property ShellScreen screen
    required property bool vertical

    readonly property var activeMonitor: Hyprland.monitorFor(root.screen)
    readonly property string activeMonitorName: activeMonitor?.name ?? ""
    readonly property int activeWorkspaceId: activeMonitor?.activeWorkspace?.id ?? -1

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    property var liveWorkspaces: []

    function isSpecialWorkspace(workspace) {
        if (!workspace) {
            return false;
        }
        return workspace.name && workspace.name.startsWith("special");
    }

    function isNamedWorkspace(workspace) {
        if (!workspace) {
            return false;
        }
        return workspace.name && workspace.name !== workspace.id.toString();
    }

    function workspaceLabel(workspace) {
        if (!workspace) {
            return "";
        }
        if (workspace.name && workspace.name !== workspace.id.toString()) {
            return workspace.name;
        }
        return workspace.id.toString();
    }

    function refreshWorkspaces() {
        const focusedId = Hyprland.focusedWorkspace?.id;
        const monitorName = root.activeMonitorName;
        liveWorkspaces = Hyprland.workspaces.values.filter(workspace => {
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
            refreshAfterEvent(event.name);
            refreshWorkspaces();
        }
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            refreshWorkspaces();
        }
    }

    Component.onCompleted: refreshWorkspaces()

    RowLayout {
        id: layout

        spacing: 6

        Repeater {
            model: root.liveWorkspaces

            delegate: WorkspacePill {
                required property var modelData

                workspaceId: modelData.id
                label: root.workspaceLabel(modelData)
                vertical: root.vertical
                active: root.activeWorkspaceId === workspaceId
                occupied: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.activate()
                }
            }
        }
    }
}
