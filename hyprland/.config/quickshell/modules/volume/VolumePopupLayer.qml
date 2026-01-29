import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

import "../../config" as Config
import "./"

/*!
  VolumePopupLayer
  Attaches volume popups per screen.
*/
Scope {
    id: root

    property bool shouldShowOsd: false
    property bool isInteracting: false
    property real volumeLevel: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property bool volumeMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function showOsd() {
        root.shouldShowOsd = true;
        hideTimer.restart();
    }

    onVolumeLevelChanged: showOsd()
    onVolumeMutedChanged: showOsd()

    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
            root.showOsd();
        }

        function onMutedChanged() {
            root.showOsd();
        }
    }

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

        VolumePopup {
            required property var modelData

            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool isFocused: !Hyprland.focusedMonitor || monitor === Hyprland.focusedMonitor

            screen: modelData
            active: root.shouldShowOsd && isFocused

            onInteractingChanged: {
                root.isInteracting = interacting;
                root.showOsd();
            }
        }
    }
}
