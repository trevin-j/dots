import QtQuick
import Quickshell

import "../services" as Services
import "../features/appdrawer" as AppDrawerFeature
import "../features/appdrawer/vm" as AppDrawerVm
import "../features/bar" as BarFeature
import "../features/controlcenter" as ControlCenterFeature
import "../features/controlcenter/vm" as ControlCenterVm
import "../features/whichkey" as WhichKeyFeature

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

    AppDrawerVm.AppDrawerState {
        id: appDrawerState
    }

    Component.onCompleted: {
        Services.ControlCenterService.registerScreenState(root.panelScreen, controlCenterState);
        Services.AppDrawerService.registerScreenState(root.panelScreen, appDrawerState);
    }

    Component.onDestruction: {
        Services.ControlCenterService.unregisterScreenState(controlCenterState);
        Services.AppDrawerService.unregisterScreenState(appDrawerState);
    }

    BarFeature.BarPanelFeature {
        panelScreen: root.panelScreen
        controlCenterState: controlCenterState
    }

    ControlCenterFeature.ControlCenterPanelFeature {
        panelScreen: root.panelScreen
        state: controlCenterState
    }

    AppDrawerFeature.AppDrawerPanelFeature {
        panelScreen: root.panelScreen
        state: appDrawerState
    }

    WhichKeyFeature.WhichKeyLayerFeature {
        panelScreen: root.panelScreen
    }
}
