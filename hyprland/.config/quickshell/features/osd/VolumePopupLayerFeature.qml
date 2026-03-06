import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

import "../../config" as Config
import "../../services" as Services
import "./components" as OsdComponents

/*
  VolumePopupLayerFeature
  Attaches volume OSD popups per screen.
*/
Scope {
    id: root

    property bool shouldShowOsd: false
    property bool isInteracting: false
    property real volumeLevel: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property bool volumeMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    property bool hasTrackedVolume: false
    property real previousVolumeLevel: 0

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

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function showOsd() {
        root.shouldShowOsd = true;
        hideTimer.restart();
    }

    function handleVolumeLevelChanged() {
        const nextLevel = root.volumeLevel;
        if (!root.hasTrackedVolume) {
            root.previousVolumeLevel = nextLevel;
            root.hasTrackedVolume = true;
            root.showOsd();
            return;
        }

        const delta = nextLevel - root.previousVolumeLevel;
        root.previousVolumeLevel = nextLevel;
        root.showOsd();
        Services.VolumeFeedbackService.playForDelta(delta);
    }

    onVolumeLevelChanged: handleVolumeLevelChanged()
    onVolumeMutedChanged: showOsd()

    Timer {
        id: hideTimer

        interval: Config.Config.popouts?.volume?.hideDelay ?? 1500
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

        OsdComponents.VolumePopup {
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
