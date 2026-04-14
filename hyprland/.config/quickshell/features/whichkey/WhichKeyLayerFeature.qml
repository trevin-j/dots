import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../../config" as Config
import "../../services" as Services
import "./components" as WhichKeyComponents
import "./vm" as WhichKeyVm

/*
  WhichKeyLayerFeature
  Attaches which-key overlay popups per screen and routes commands through service IO.
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
        if (!monitorKeyValue || !focusedKeyValue) {
            return true;
        }
        return monitorKeyValue === focusedKeyValue;
    }

    WhichKeyVm.WhichKeyState {
        id: whichKeyState

        config: Config.Config.whichKey ?? ({})
    }

    Component.onCompleted: Services.WhichKeyService.registerState(whichKeyState)
    Component.onDestruction: Services.WhichKeyService.unregisterState(whichKeyState)

    Connections {
        target: whichKeyState

        function onCommandRequested(command) {
            Services.WhichKeyService.executeCommand(command);
        }
    }

    Variants {
        model: Quickshell.screens

        WhichKeyComponents.WhichKeyPopup {
            required property var modelData

            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool isFocused: root.isFocusedMonitor(monitor)

            panelScreen: modelData
            active: whichKeyState.open && whichKeyState.enabled && isFocused
            viewModel: whichKeyState
            style: Config.Config.whichKey?.panel ?? ({})
        }
    }
}
