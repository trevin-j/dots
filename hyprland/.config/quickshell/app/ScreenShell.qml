import QtQuick
import Quickshell

import "../features/bar" as BarFeature
import "../features/chrome" as ChromeFeature
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

    BarFeature.BarPanelFeature {
        panelScreen: root.panelScreen
        controlCenterState: controlCenterState
    }

    ControlCenterFeature.ControlCenterBackdropFeature {
        panelScreen: root.panelScreen
        state: controlCenterState
    }

    ControlCenterFeature.ControlCenterPanelFeature {
        panelScreen: root.panelScreen
        state: controlCenterState
    }

    ChromeFeature.BottomCornerCutoutsFeature {
        panelScreen: root.panelScreen
    }
}
