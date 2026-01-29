import QtQuick
import Quickshell

import "../../components" as Shared
import "../../config" as Config

/*!
  FrameOverlay
  Per-screen overlay hosting the global frame and attached bubble layer.
  Required properties: screen.
*/
PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property string barPosition: Config.Config.bar.position || "top"
    readonly property int barThickness: Config.Config.bar.size?.thickness ?? 36
    readonly property real barCornerRadius: Math.min(Config.Appearance.radiusLarge, barThickness * 0.5)
    readonly property int barMarginTop: Config.Config.bar.size?.marginTop ?? 0
    readonly property int barMarginSide: Config.Config.bar.size?.marginSide ?? 0
    readonly property int barMarginBottom: Config.Config.bar.size?.marginBottom ?? 0

    readonly property real reservedBarExtent: Config.Config.appearance.frame?.reservedBarExtent
        ?? (barPosition === "top"
            ? barThickness + barCornerRadius + barMarginTop
            : barPosition === "left"
                ? barThickness + barMarginSide
                : barPosition === "bottom"
                    ? barThickness + barCornerRadius + barMarginBottom
                    : 0)

    readonly property real leftMargin: barPosition === "left" ? reservedBarExtent : 0
    readonly property real topMargin: barPosition === "top" ? reservedBarExtent : 0

    readonly property real borderThickness: Config.Appearance.frameBorderThickness
    readonly property real borderRounding: Config.Appearance.frameBorderRounding
    readonly property string frameColorRole: Config.Appearance.frameColorRole
    readonly property color cutoutBlack: Config.Appearance.cutoutBlack

    screen: root.screen
    aboveWindows: true
    focusable: false
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0

    mask: Region {
        item: inputPassthrough
        intersection: Intersection.Xor
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Shared.AttachedBubbleLayer {
        anchors.fill: parent
        screen: root.screen
        frameInnerX: root.borderThickness + root.leftMargin
        frameInnerY: root.borderThickness + root.topMargin
        frameInnerWidth: Math.max(0, width - root.borderThickness * 2 - root.leftMargin)
        frameInnerHeight: Math.max(0, height - root.borderThickness * 2 - root.topMargin)
    }

    Shared.ScreenFrame {
        anchors.fill: parent
        borderThickness: root.borderThickness
        borderRounding: root.borderRounding
        frameColor: Config.Palette.color(frameColorRole)
        leftMargin: root.leftMargin
        topMargin: root.topMargin
    }

    Item {
        id: screenCutouts

        anchors.fill: parent
        visible: root.borderRounding > 0
        z: 2

        Shared.CornerCutout {
            radius: root.borderRounding
            fillColor: root.cutoutBlack
            mirrorY: true
            anchors.left: parent.left
            anchors.bottom: parent.bottom
        }

        Shared.CornerCutout {
            radius: root.borderRounding
            fillColor: root.cutoutBlack
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
