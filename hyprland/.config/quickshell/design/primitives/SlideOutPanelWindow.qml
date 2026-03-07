import QtQuick
import Quickshell

/*
  SlideOutPanelWindow
  Full-screen shell window host for one or more in-window slide surfaces.
  Required properties: panelScreen.
*/
PanelWindow {
    id: root

    required property ShellScreen panelScreen

    property bool open: false
    property int closeDurationMs: 0
    readonly property bool presentationOpen: root.open || root._retainVisible

    default property alias windowContent: contentHost.data
    readonly property alias contentItem: contentHost

    property bool _retainVisible: false

    screen: root.panelScreen
    aboveWindows: true
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    visible: root.presentationOpen

    onOpenChanged: {
        if (root.open) {
            closeRetainTimer.stop();
            root._retainVisible = true;
        } else {
            root._retainVisible = true;
            closeRetainTimer.restart();
        }
    }

    Component.onCompleted: {
        root._retainVisible = root.open;
    }

    Timer {
        id: closeRetainTimer

        interval: Math.max(0, root.closeDurationMs)
        repeat: false
        onTriggered: root._retainVisible = false
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
