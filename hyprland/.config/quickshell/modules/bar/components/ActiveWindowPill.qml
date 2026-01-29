import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

import "../../../config" as Config
import "../../../utils"

/*!
  ActiveWindowPill
  Shows the current active application icon and name.
  Required properties: screen (ShellScreen).
*/
Item {
    id: root

    required property ShellScreen screen

    readonly property var activeMonitor: Hyprland.monitorFor(root.screen)
    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property var activeWorkspace: activeMonitor?.activeWorkspace || Hyprland.focusedWorkspace

    readonly property int horizontalPadding: Config.Config.bar.size?.spacing || 8
    readonly property int verticalPadding: Math.max(4, Math.round(horizontalPadding / 2))
    readonly property int iconSize: Math.max(14, Math.round(Config.Appearance.fontSizeLarge))
    readonly property int minHeight: 24

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

    readonly property bool hasActiveWindow: resolvedToplevel !== null && resolvedToplevel.title !== "" && resolvedToplevel.title !== undefined && activeWorkspace && resolvedToplevel.workspace === activeWorkspace && activeWorkspaceWindowCount > 0

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

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    opacity: hasActiveWindow ? 1 : 0

    Behavior on opacity {
        Anim {
            durationMs: Config.Motion.mediumDuration
            curve: Config.Motion.standardCurve
        }
    }

    Rectangle {
        id: pill

        radius: Config.Appearance.radiusMedium
        color: Config.Palette.color("surface_container")

        implicitWidth: Math.max(minHeight, contentRow.implicitWidth + root.horizontalPadding * 2)
        implicitHeight: Math.max(contentRow.implicitHeight + root.verticalPadding * 2, minHeight)

        Behavior on implicitWidth {
            Anim {
            durationMs: Config.Motion.longDuration
            curve: Config.Motion.emphasizedCurve

            }
        }

        RowLayout {
            id: contentRow

            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
            anchors.topMargin: root.verticalPadding
            anchors.bottomMargin: root.verticalPadding
            spacing: Math.round(root.horizontalPadding / 2)

            IconImage {
                id: appIcon

                implicitSize: root.iconSize
                source: root.iconSource
                visible: source !== ""
                asynchronous: true
                mipmap: true

                Layout.preferredWidth: visible ? implicitWidth : 0
                Layout.preferredHeight: visible ? implicitHeight : 0
                Layout.alignment: Qt.AlignVCenter
                opacity: hasActiveWindow ? 1 : 0

                Behavior on opacity {
                    Anim {
                        durationMs: Config.Motion.shortDuration
                        curve: Config.Motion.standardCurve

                    }
                }
            }

            Text {
                id: titleText

                text: root.displayName
                color: Config.Palette.color("on_surface")
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                opacity: hasActiveWindow ? 1 : 0

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Behavior on opacity {
                    Anim {
                        durationMs: Config.Motion.shortDuration
                        curve: Config.Motion.standardCurve

                    }
                }
            }
        }
    }

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
