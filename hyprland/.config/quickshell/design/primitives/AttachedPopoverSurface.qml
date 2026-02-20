import QtQuick
import Quickshell

import "../../config" as Config
import "../../utils"
import "./" as Primitives

/*
  AttachedPopoverSurface
  Shared attached popover shell with animated open/close behavior.
*/
PanelWindow {
    id: root

    required property ShellScreen screen
    required property bool open
    required property int topMargin
    required property int rightMargin
    required property int widthValue
    required property int targetHeight
    required property int cornerRadius
    required property color surfaceColor

    property int contentPadding: 0
    property string attachEdge: "top-right"
    property bool maskEnabled: true
    property bool blockMask: false
    property real closedXOffset: 0
    property real closedOpacity: 1

    readonly property bool hovered: hoverHandler.hovered
    readonly property alias bodyItem: body
    property alias contentData: contentRoot.data
    property alias chromeData: chromeLayer.data
    property alias overlayData: overlayLayer.data

    visible: root.open || wrapper.height > 0
    color: "transparent"
    surfaceFormat.opaque: false
    focusable: true
    exclusiveZone: 0
    aboveWindows: true

    anchors.top: true
    anchors.right: true
    margins.top: root.topMargin
    margins.right: root.rightMargin

    implicitWidth: wrapper.implicitWidth
    implicitHeight: wrapper.implicitHeight

    mask: (root.open && root.maskEnabled && !root.blockMask) ? windowMask : null

    Region {
        id: windowMask
        item: body
    }

    Primitives.SurfaceShadow {
        source: wrapper
        enabled: Config.Appearance.shadowEnabled && (root.open || wrapper.height > 0)
    }

    Primitives.FrameWrapper {
        id: wrapper

        screen: root.screen
        attachEdge: root.attachEdge
        active: root.open
        bubbleColorRole: "surface"
        bubblePadding: 0
        bubbleRounding: root.cornerRadius

        width: implicitWidth
        height: root.open ? Math.round(root.targetHeight + root.cornerRadius) : 0
        implicitWidth: root.widthValue + root.cornerRadius
        implicitHeight: root.targetHeight + root.cornerRadius
        clip: true
        visible: root.open || height > 0
        x: root.open ? 0 : root.closedXOffset
        opacity: root.open ? 1 : root.closedOpacity

        anchors.top: parent.top

        Behavior on height {
            Anim {
                durationMs: Config.Motion.shellDuration
                curve: Config.Motion.shellCurve
            }
        }

        Behavior on x {
            Anim {
                durationMs: Config.Motion.shellDuration
                curve: Config.Motion.shellCurve
            }
        }

        Behavior on opacity {
            Anim {
                durationMs: Config.Motion.shellDuration
                curve: Config.Motion.shellCurve
            }
        }

        Item {
            width: root.widthValue + root.cornerRadius
            height: root.targetHeight + root.cornerRadius
            anchors.top: parent.top

            Rectangle {
                id: body

                width: root.widthValue
                height: root.targetHeight
                x: root.cornerRadius
                radius: root.cornerRadius
                color: root.surfaceColor
            }

            Rectangle {
                width: root.cornerRadius
                height: root.cornerRadius
                anchors.left: body.left
                anchors.top: body.top
                color: body.color
                z: 1
            }

            Rectangle {
                width: root.cornerRadius
                height: root.cornerRadius
                anchors.right: body.right
                anchors.top: body.top
                color: body.color
                z: 1
            }

            Rectangle {
                width: root.cornerRadius
                height: root.cornerRadius
                anchors.right: body.right
                anchors.bottom: body.bottom
                color: body.color
                z: 1
            }

            Item {
                id: chromeLayer

                anchors.fill: parent
                z: 2
            }

            Item {
                id: contentRoot

                anchors.fill: body
                anchors.leftMargin: root.contentPadding
                anchors.topMargin: root.contentPadding
                anchors.rightMargin: root.contentPadding
                anchors.bottomMargin: root.contentPadding
                z: 3
            }

            Item {
                id: overlayLayer

                anchors.fill: body
                z: 4
            }
        }

        HoverHandler {
            id: hoverHandler
            target: wrapper
        }
    }
}
