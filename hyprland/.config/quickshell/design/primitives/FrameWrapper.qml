import QtQuick
import Quickshell

import "../../config" as Config

/*
  FrameWrapper
  Registers popup/panel geometry for global attached bubble rendering.
*/
Item {
    id: root

    required property ShellScreen screen
    required property string attachEdge
    required property bool active

    property string bubbleColorRole: "surface_container_high"
    property real bubblePadding: Config.Appearance.bubblePadding
    property real bubbleRounding: Config.Appearance.bubbleRounding

    readonly property bool bubbleVisible: width > 0 && height > 0 && visible
    readonly property real globalX: mapToGlobal(0, 0).x
    readonly property real globalY: mapToGlobal(0, 0).y

}
