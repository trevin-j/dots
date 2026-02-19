import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../../config" as Config
import "../../services" as Services
import "./components" as OsdComponents

/*
  BrightnessPopupLayerFeature
  Attaches brightness OSD popups per screen.
*/
Scope {
    id: root

    property bool shouldShowOsd: false
    property bool isInteracting: false
    property real brightnessLevel: Services.BrightnessService.level

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

    function showOsd() {
        root.shouldShowOsd = true;
        hideTimer.restart();
    }

    onBrightnessLevelChanged: showOsd()

    Connections {
        target: Services.BrightnessService

        function onLevelChanged() {
            root.showOsd();
        }
    }

    Timer {
        id: hideTimer

        interval: Config.Config.popouts?.brightness?.hideDelay ?? 1500
        repeat: false
        onTriggered: {
            if (root.isInteracting) {
                hideTimer.restart();
                return;
            }
            root.shouldShowOsd = false;
        }
    }

    Variants {
        model: Quickshell.screens

        OsdComponents.BrightnessPopup {
            required property var modelData

            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool isFocused: root.isFocusedMonitor(monitor)

            screen: modelData
            active: root.shouldShowOsd && isFocused

            onInteractingChanged: {
                root.isInteracting = interacting;
                root.showOsd();
            }
        }
    }
}
