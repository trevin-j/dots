import QtQuick
import Quickshell

import "../../config" as Config
import "../../services" as Services
import "./components" as WhichKeyComponents
import "./vm" as WhichKeyVm

/*
  WhichKeyLayerFeature
  Per-screen which-key overlay host and state registration.
  Required properties: panelScreen.
 */
Scope {
    id: root

    required property ShellScreen panelScreen

    WhichKeyVm.WhichKeyState {
        id: whichKeyState

        config: Config.Config.whichKey ?? ({})
    }

    Component.onCompleted: Services.WhichKeyService.registerScreenState(root.panelScreen, whichKeyState)
    Component.onDestruction: Services.WhichKeyService.unregisterScreenState(whichKeyState)

    Connections {
        target: whichKeyState

        function onCommandRequested(command) {
            Services.WhichKeyService.executeCommand(command);
        }
    }

    WhichKeyComponents.WhichKeyPopup {
        panelScreen: root.panelScreen
        active: whichKeyState.open && whichKeyState.enabled
        viewModel: whichKeyState
        style: Config.Config.whichKey?.panel ?? ({})
    }
}
