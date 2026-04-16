import QtQuick
import Quickshell

import "../services" as Services
import "../features/appdrawer" as AppDrawerFeature
import "../features/appdrawer/vm" as AppDrawerVm
import "../features/bar" as BarFeature
import "../features/clipboardhistory" as ClipboardHistoryFeature
import "../features/clipboardhistory/vm" as ClipboardHistoryVm
import "../features/controlcenter" as ControlCenterFeature
import "../features/controlcenter/vm" as ControlCenterVm
import "../features/whichkey" as WhichKeyFeature
import "../features/workspacerename" as WorkspaceRenameFeature

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

    ClipboardHistoryVm.ClipboardHistoryState {
        id: clipboardHistoryState
    }

    Component.onCompleted: {
        Services.ControlCenterService.registerScreenState(root.panelScreen, controlCenterState);
        Services.AppDrawerService.registerScreenState(root.panelScreen, appDrawerState);
        Services.ClipboardHistoryService.registerScreenState(root.panelScreen, clipboardHistoryState);
    }

    Component.onDestruction: {
        Services.ControlCenterService.unregisterScreenState(controlCenterState);
        Services.AppDrawerService.unregisterScreenState(appDrawerState);
        Services.ClipboardHistoryService.unregisterScreenState(clipboardHistoryState);
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

    ClipboardHistoryFeature.ClipboardHistoryPanelFeature {
        panelScreen: root.panelScreen
        state: clipboardHistoryState
    }

    WhichKeyFeature.WhichKeyLayerFeature {
        panelScreen: root.panelScreen
    }

    WorkspaceRenameFeature.WorkspaceRenamePanelFeature {
        id: workspaceRenamePanel

        panelScreen: root.panelScreen
        Component.onCompleted: Services.WorkspaceService.setPanel(workspaceRenamePanel)
        Component.onDestruction: Services.WorkspaceService.setPanel(null)
    }
}
