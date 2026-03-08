import QtQuick

import "../../config" as Config
import "../../utils"
import "./" as Primitives

/*
  SlideOutPanelSurface
  Directional in-window sliding surface with cutouts and shadow.
  Required properties: attachedEdge, primaryExtent.
*/
Item {
    id: root

    required property string attachedEdge
    required property int primaryExtent

    property int attachedInset: 0
    property int overshootPadding: Math.max(72, Math.round(primaryExtent * 0.22))
    property int openDelay: 0
    property bool active: open
    property bool open: false
    property bool renderWhenClosed: true
    property color surfaceColor: Config.Palette.color("surface")
    property int openDurationMs: Config.Motion.shellDuration
    property int closeDurationMs: Config.Motion.shortDuration
    property var openCurve: Config.Motion.shellCurve
    property var closeCurve: Config.Motion.emphasizedAccelCurve
    property bool shadowEnabled: Config.Appearance.shadowEnabled
    property real shadowOffsetX: 0
    property real shadowOffsetY: Config.Appearance.shadowOffsetY
    readonly property bool presentationOpen: root.active || root._retainVisible

    readonly property bool horizontal: attachedEdge === "left" || attachedEdge === "right"
    readonly property bool attachedRight: attachedEdge === "right"
    readonly property bool attachedLeft: attachedEdge === "left"
    readonly property bool attachedTop: attachedEdge === "top"
    readonly property bool attachedBottom: attachedEdge === "bottom"
    readonly property int totalExtent: primaryExtent + overshootPadding
    readonly property int cornerRadius: Config.Appearance.frameBorderRounding
    readonly property int edgeInset: Math.round(Math.max(0, primaryExtent - Math.max(0, drawerOffset)))
    readonly property bool shouldRenderSurface: root.presentationOpen
        && (root.renderWhenClosed || root.edgeInset > 0 || root.drawerOpen || root.open)
    readonly property real drawerX: attachedRight
        ? width - attachedInset - primaryExtent + drawerOffset
        : attachedLeft
            ? attachedInset - overshootPadding - drawerOffset
            : 0
    readonly property real drawerY: attachedBottom
        ? height - attachedInset - primaryExtent + drawerOffset
        : attachedTop
            ? attachedInset - overshootPadding - drawerOffset
            : 0
    readonly property real visibleSurfaceX: attachedRight
        ? drawerX
        : attachedLeft
            ? drawerX + overshootPadding
            : 0
    readonly property real visibleSurfaceY: attachedBottom
        ? drawerY
        : attachedTop
            ? drawerY + overshootPadding
            : 0

    readonly property alias contentHostItem: contentHost
    readonly property alias surfaceItem: visibleSurface

    default property alias panelContent: contentHost.data

    property bool drawerOpen: false
    property bool drawerClosingMotion: false
    property real drawerOffset: drawerOpen ? 0 : primaryExtent
    property bool _retainVisible: false

    visible: root.presentationOpen || root.drawerOpen || root.drawerOffset < root.primaryExtent

    onVisibleChanged: {
        if (!visible) {
            root.drawerOpen = false;
            openDelayTimer.stop();
        }
    }

    onActiveChanged: {
        if (root.active) {
            closeRetainTimer.stop();
            root._retainVisible = true;
            root.drawerClosingMotion = false;
            if (root.open) {
                if (root.openDelay <= 0) {
                    root.drawerOpen = true;
                } else {
                    openDelayTimer.restart();
                }
            }
        } else {
            root._retainVisible = true;
            closeRetainTimer.restart();
            root.drawerClosingMotion = true;
            openDelayTimer.stop();
            root.drawerOpen = false;
        }
    }

    Component.onCompleted: {
        root._retainVisible = root.active;
        if (root.active) {
            root.drawerClosingMotion = false;
            if (root.open && root.openDelay <= 0) {
                root.drawerOpen = true;
            } else if (root.open) {
                openDelayTimer.restart();
            }
        }
    }

    property Timer closeRetainTimer: Timer {
        id: closeRetainTimer

        interval: Math.max(0, root.closeDurationMs)
        repeat: false
        onTriggered: root._retainVisible = false
    }

    onOpenChanged: {
        if (!root.active) {
            openDelayTimer.stop();
            root.drawerOpen = false;
            return;
        }

        if (root.open) {
            root.drawerClosingMotion = false;
            if (root.openDelay <= 0) {
                root.drawerOpen = true;
            } else {
                openDelayTimer.restart();
            }
        } else {
            root.drawerClosingMotion = true;
            openDelayTimer.stop();
            root.drawerOpen = false;
        }
    }

    Timer {
        id: openDelayTimer

        interval: root.openDelay
        repeat: false
        onTriggered: {
            if (root.active && root.open) {
                root.drawerOpen = true;
            }
        }
    }

    Behavior on drawerOffset {
        Anim {
            durationMs: root.drawerClosingMotion ? root.closeDurationMs : root.openDurationMs
            curve: root.drawerClosingMotion ? root.closeCurve : root.openCurve
        }
    }

    Item {
        id: shadowShape

        width: root.horizontal
            ? root.totalExtent + (root.attachedRight ? root.cornerRadius : 0) + (root.attachedLeft ? root.cornerRadius : 0)
            : parent.width
        height: root.horizontal
            ? parent.height
            : root.totalExtent + (root.attachedBottom ? root.cornerRadius : 0) + (root.attachedTop ? root.cornerRadius : 0)
        x: root.horizontal
            ? root.drawerX - (root.attachedRight ? root.cornerRadius : 0)
            : 0
        y: root.horizontal
            ? 0
            : root.drawerY - (root.attachedBottom ? root.cornerRadius : 0)
        visible: root.shouldRenderSurface
        opacity: 0

        Rectangle {
            id: shadowBody

            x: root.horizontal && root.attachedRight ? root.cornerRadius : 0
            y: !root.horizontal && root.attachedBottom ? root.cornerRadius : 0
            width: root.horizontal ? root.totalExtent : parent.width
            height: root.horizontal ? parent.height : root.totalExtent
            color: root.surfaceColor
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0 && root.horizontal && root.attachedRight
            radius: root.cornerRadius
            fillColor: root.surfaceColor
            mirrorX: true
            anchors.right: shadowBody.left
            anchors.top: shadowBody.top
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0 && root.horizontal && root.attachedRight
            radius: root.cornerRadius
            fillColor: root.surfaceColor
            mirrorX: true
            mirrorY: true
            anchors.right: shadowBody.left
            anchors.bottom: shadowBody.bottom
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0 && root.horizontal && root.attachedLeft
            radius: root.cornerRadius
            fillColor: root.surfaceColor
            anchors.left: shadowBody.right
            anchors.top: shadowBody.top
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0 && root.horizontal && root.attachedLeft
            radius: root.cornerRadius
            fillColor: root.surfaceColor
            mirrorY: true
            anchors.left: shadowBody.right
            anchors.bottom: shadowBody.bottom
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0 && !root.horizontal && root.attachedBottom
            radius: root.cornerRadius
            fillColor: root.surfaceColor
            mirrorY: true
            anchors.left: shadowBody.left
            anchors.bottom: shadowBody.top
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0 && !root.horizontal && root.attachedBottom
            radius: root.cornerRadius
            fillColor: root.surfaceColor
            mirrorX: true
            mirrorY: true
            anchors.right: shadowBody.right
            anchors.bottom: shadowBody.top
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0 && !root.horizontal && root.attachedTop
            radius: root.cornerRadius
            fillColor: root.surfaceColor
            anchors.left: shadowBody.left
            anchors.top: shadowBody.bottom
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0 && !root.horizontal && root.attachedTop
            radius: root.cornerRadius
            fillColor: root.surfaceColor
            mirrorX: true
            anchors.right: shadowBody.right
            anchors.top: shadowBody.bottom
        }
    }

    Primitives.SurfaceShadow {
        source: shadowShape
        enabled: root.edgeInset > 0 && root.shadowEnabled
        offsetX: root.shadowOffsetX
        offsetY: root.shadowOffsetY
    }

    Item {
        id: drawer

        width: root.horizontal ? root.totalExtent : parent.width
        height: root.horizontal ? parent.height : root.totalExtent
        x: root.horizontal ? root.drawerX : 0
        y: root.horizontal ? 0 : root.drawerY
        clip: false
        visible: root.shouldRenderSurface

        Rectangle {
            id: body

            anchors.fill: parent
            radius: 0
            color: root.surfaceColor
        }

        Item {
            id: visibleSurface

            x: root.horizontal ? (root.attachedLeft ? root.overshootPadding : 0) : 0
            y: root.horizontal ? 0 : (root.attachedTop ? root.overshootPadding : 0)
            width: root.horizontal ? root.primaryExtent : parent.width
            height: root.horizontal ? parent.height : root.primaryExtent

            Item {
                id: contentHost
                anchors.fill: parent
            }
        }

        Primitives.CornerCutout {
            visible: root.edgeInset > 0 && root.horizontal && root.attachedRight
            radius: root.cornerRadius
            fillColor: body.color
            mirrorX: true
            anchors.right: visibleSurface.left
            anchors.top: visibleSurface.top
        }

        Primitives.CornerCutout {
            visible: root.edgeInset > 0 && root.horizontal && root.attachedRight
            radius: root.cornerRadius
            fillColor: body.color
            mirrorX: true
            mirrorY: true
            anchors.right: visibleSurface.left
            anchors.bottom: visibleSurface.bottom
        }

        Primitives.CornerCutout {
            visible: root.edgeInset > 0 && root.horizontal && root.attachedLeft
            radius: root.cornerRadius
            fillColor: body.color
            anchors.left: visibleSurface.right
            anchors.top: visibleSurface.top
        }

        Primitives.CornerCutout {
            visible: root.edgeInset > 0 && root.horizontal && root.attachedLeft
            radius: root.cornerRadius
            fillColor: body.color
            mirrorY: true
            anchors.left: visibleSurface.right
            anchors.bottom: visibleSurface.bottom
        }

        Primitives.CornerCutout {
            visible: root.edgeInset > 0 && !root.horizontal && root.attachedBottom
            radius: root.cornerRadius
            fillColor: body.color
            mirrorY: true
            anchors.left: visibleSurface.left
            anchors.bottom: visibleSurface.top
        }

        Primitives.CornerCutout {
            visible: root.edgeInset > 0 && !root.horizontal && root.attachedBottom
            radius: root.cornerRadius
            fillColor: body.color
            mirrorX: true
            mirrorY: true
            anchors.right: visibleSurface.right
            anchors.bottom: visibleSurface.top
        }

        Primitives.CornerCutout {
            visible: root.edgeInset > 0 && !root.horizontal && root.attachedTop
            radius: root.cornerRadius
            fillColor: body.color
            anchors.left: visibleSurface.left
            anchors.top: visibleSurface.bottom
        }

        Primitives.CornerCutout {
            visible: root.edgeInset > 0 && !root.horizontal && root.attachedTop
            radius: root.cornerRadius
            fillColor: body.color
            mirrorX: true
            anchors.right: visibleSurface.right
            anchors.top: visibleSurface.bottom
        }
    }
}
