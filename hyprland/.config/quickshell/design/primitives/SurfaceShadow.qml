import QtQuick
import QtQuick.Effects

import "../../config" as Config

/*
  SurfaceShadow
  Renders a drop shadow from a single source silhouette item.
  Required properties: source.
*/
Item {
    id: root

    required property Item source

    property bool enabled: Config.Appearance.shadowEnabled
    property color shadowColor: Config.Palette.shadow
    property real blur: Config.Appearance.shadowBlur
    property real shadowOpacityAmount: Config.Appearance.shadowOpacity
    property real offsetX: 0
    property real offsetY: Config.Appearance.shadowOffsetY
    property real shadowScaleAmount: 1

    anchors.fill: source
    z: -1

    visible: enabled && source.width > 0 && source.height > 0

    MultiEffect {
        anchors.fill: parent
        source: root.source

        autoPaddingEnabled: true
        shadowEnabled: root.visible
        shadowColor: root.shadowColor
        shadowOpacity: Math.max(0, Math.min(1, root.shadowOpacityAmount))
        shadowHorizontalOffset: root.offsetX
        shadowVerticalOffset: root.offsetY
        shadowScale: Math.max(0, root.shadowScaleAmount)
        shadowBlur: 1
        blurMax: Math.max(1, Math.round(root.blur))

        maskEnabled: true
        maskSource: root.source
        maskInverted: true
        maskThresholdMin: Math.max(0, Math.min(1, Config.Appearance.frameMaskThresholdMin))
        maskThresholdMax: 1.0
        maskSpreadAtMin: Math.max(0, Math.min(1, Config.Appearance.frameMaskSpreadAtMin))
        maskSpreadAtMax: 0.0
    }
}
