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
import "../features/emoji" as EmojiFeature
import "../features/nerdfont" as NerdFontFeature
import "../features/symbolpicker/vm" as SymbolPickerVm
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

    SymbolPickerVm.SymbolPickerState {
        id: emojiState
    }

    SymbolPickerVm.SymbolPickerState {
        id: nerdFontState
    }

    Component.onCompleted: {
        Services.ControlCenterService.registerScreenState(root.panelScreen, controlCenterState);
        Services.AppDrawerService.registerScreenState(root.panelScreen, appDrawerState);
        Services.ClipboardHistoryService.registerScreenState(root.panelScreen, clipboardHistoryState);
        Services.SymbolPickerService.registerScreenState("emoji", root.panelScreen, emojiState);
        Services.SymbolPickerService.registerScreenState("nerdfont", root.panelScreen, nerdFontState);
    }

    Component.onDestruction: {
        Services.ControlCenterService.unregisterScreenState(controlCenterState);
        Services.AppDrawerService.unregisterScreenState(appDrawerState);
        Services.ClipboardHistoryService.unregisterScreenState(clipboardHistoryState);
        Services.SymbolPickerService.unregisterScreenState("emoji", emojiState);
        Services.SymbolPickerService.unregisterScreenState("nerdfont", nerdFontState);
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

    EmojiFeature.EmojiPanelFeature {
        panelScreen: root.panelScreen
        state: emojiState
    }

    NerdFontFeature.NerdFontPanelFeature {
        panelScreen: root.panelScreen
        state: nerdFontState
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
