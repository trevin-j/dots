import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../config" as Config
import "./vm" as ControlCenterVm

/*
  ControlCenterBackdropFeature
  Full-screen blur target and scrim behind the control center drawer.
  Required properties: panelScreen, state.
*/
PanelWindow {
    id: root

    required property ShellScreen panelScreen
    required property ControlCenterVm.ControlCenterState state

    readonly property real targetOpacity: Config.Config.controlCenter?.backdrop?.scrimOpacity ?? 0.24
    readonly property bool active: root.state.open || root.state.edgeInset > 0

    screen: root.panelScreen
    aboveWindows: true
    focusable: false
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0

    WlrLayershell.namespace: "qs-control-center-backdrop"
    WlrLayershell.layer: WlrLayer.Top

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    visible: root.active || scrim.opacity > 0

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: Config.Palette.color("scrim")
        opacity: root.active ? root.targetOpacity : 0
    }
}
