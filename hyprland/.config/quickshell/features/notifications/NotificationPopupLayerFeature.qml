import QtQuick
import Quickshell
import Quickshell.Hyprland

import "./components" as NotificationComponents

/*
  NotificationPopupLayerFeature
  Displays per-screen notification popups on the focused monitor.
*/
Scope {
    id: root

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

    function isFocusedMonitor(monitor) {
        const focused = Hyprland.focusedMonitor;
        if (!focused || !monitor) {
            return true;
        }

        if (monitor === focused) {
            return true;
        }

        const monitorKeyValue = root.monitorKey(monitor);
        const focusedKeyValue = root.monitorKey(focused);
        return monitorKeyValue !== "" && monitorKeyValue === focusedKeyValue;
    }

    Variants {
        model: Quickshell.screens

        NotificationComponents.NotificationPopupHost {
            required property var modelData

            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool isFocused: root.isFocusedMonitor(monitor)

            screen: modelData
            active: isFocused
        }
    }
}
