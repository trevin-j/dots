import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../config" as Config
import "../../design/primitives" as Primitives

/*
  ScreenCornerCutoutsFeature
  Renders all screen corner cutouts in one top-most shell layer.
*/
PanelWindow {
    id: root

    required property ShellScreen panelScreen

    readonly property real cornerRadius: Config.Appearance.frameBorderRounding

    screen: root.panelScreen
    aboveWindows: true
    focusable: false
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-screen-corners"

    mask: Region {
        item: inputPassthrough
        intersection: Intersection.Xor
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Item {
        anchors.fill: parent
        visible: root.cornerRadius > 0

        Primitives.CornerCutout {
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            mirrorY: true
            anchors.left: parent.left
            anchors.bottom: parent.bottom
        }

        Primitives.CornerCutout {
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            mirrorX: true
            mirrorY: true
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }

    Rectangle {
        id: inputPassthrough
        anchors.fill: parent
        visible: false
    }
}
