import QtQuick
import Quickshell

import "../services" as Services
import "../features/bar" as BarFeature
import "../features/controlcenter" as ControlCenterFeature
import "../features/controlcenter/vm" as ControlCenterVm

/*
  ScreenShell
  Composes all per-screen shell windows and shared state.
  Required properties: panelScreen.
*/
Item {
    id: root

    required property ShellScreen panelScreen

    ControlCenterVm.ControlCenterState {
        id: controlCenterState
    }

    Component.onCompleted: Services.ControlCenterService.registerScreenState(root.panelScreen, controlCenterState)

    Component.onDestruction: Services.ControlCenterService.unregisterScreenState(controlCenterState)

    BarFeature.BarPanelFeature {
        panelScreen: root.panelScreen
        controlCenterState: controlCenterState
    }

    ControlCenterFeature.ControlCenterPanelFeature {
        panelScreen: root.panelScreen
        state: controlCenterState
    }
}
