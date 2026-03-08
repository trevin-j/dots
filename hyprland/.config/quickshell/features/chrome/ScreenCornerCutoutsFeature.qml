import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../../config" as Config
import "../../design/primitives" as Primitives

/*
  ScreenCornerCutoutsFeature
  Renders all screen corner cutouts in one top-most shell layer.
*/
PanelWindow {
    id: root

    required property ShellScreen panelScreen

    readonly property real cornerRadius: Config.Appearance.frameBorderRounding
    readonly property var activeMonitor: Hyprland.monitorFor(root.panelScreen)
    readonly property var activeWorkspace: activeMonitor?.activeWorkspace
    readonly property var activeWorkspaceToplevels: activeWorkspace?.toplevels?.values ?? []
    readonly property bool workspaceHasFullscreen: {
        for (const toplevel of root.activeWorkspaceToplevels) {
            if (!toplevel) {
                continue;
            }

            const ipc = toplevel.lastIpcObject || ({});
            if (toplevel.fullscreen || ipc.fullscreen || ipc.fullscreenClient) {
                return true;
            }
        }

        return false;
    }

    screen: root.panelScreen
    aboveWindows: true
    focusable: false
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screen-corners"

    mask: Region {
        item: inputPassthrough
        intersection: Intersection.Xor
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Item {
        anchors.fill: parent
        visible: root.cornerRadius > 0 && !root.workspaceHasFullscreen

        Primitives.CornerCutout {
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            mirrorY: true
            anchors.left: parent.left
            anchors.bottom: parent.bottom
        }

        Primitives.CornerCutout {
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            mirrorX: true
            mirrorY: true
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }

    Rectangle {
        id: inputPassthrough
        anchors.fill: parent
        visible: false
    }
}
