import QtQuick
import Quickshell

import "../../config" as Config
import "../../services" as Services

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

    readonly property var windowTransform: QSWindow.window?.windowTransform
    readonly property bool bubbleVisible: width > 0 && height > 0 && visible
    readonly property real globalX: {
        windowTransform;
        return mapToGlobal(0, 0).x;
    }
    readonly property real globalY: {
        windowTransform;
        return mapToGlobal(0, 0).y;
    }

    Component.onCompleted: Services.FrameRegistry.registerWrapper(root)
    Component.onDestruction: Services.FrameRegistry.unregisterWrapper(root)
}
