pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import "./" as ConfigFiles

QtObject {
    id: root

    readonly property string fontFamily: ConfigFiles.Config.appearance.font?.family || "Roboto"
    readonly property string iconFontFamily: ConfigFiles.Config.appearance.font?.iconFamily || "Material Symbols Rounded"
    readonly property int fontWeight: ConfigFiles.Config.appearance.font?.weight || 400
    readonly property real fontSizeSmall: ConfigFiles.Config.appearance.font?.size?.small || 11
    readonly property real fontSizeMedium: ConfigFiles.Config.appearance.font?.size?.medium || 13
    readonly property real fontSizeLarge: ConfigFiles.Config.appearance.font?.size?.large || 16

    readonly property real radiusSmall: ConfigFiles.Config.appearance.radius?.small || 6
    readonly property real radiusMedium: ConfigFiles.Config.appearance.radius?.medium || 12
    readonly property real radiusLarge: ConfigFiles.Config.appearance.radius?.large || 18

    readonly property real frameBorderThickness: ConfigFiles.Config.appearance.frame?.borderThickness ?? 2
    readonly property real frameBorderRounding: ConfigFiles.Config.appearance.frame?.borderRounding ?? radiusLarge
    readonly property real bubbleRounding: ConfigFiles.Config.appearance.frame?.bubbleRounding ?? radiusMedium
    readonly property real bubblePadding: ConfigFiles.Config.appearance.frame?.bubblePadding ?? 6
    readonly property real frameReservedBarExtent: ConfigFiles.Config.appearance.frame?.reservedBarExtent ?? 0
    readonly property string frameColorRole: ConfigFiles.Config.appearance.frame?.frameColorRole ?? "outline_variant"
    readonly property real frameMaskThresholdMin: ConfigFiles.Config.appearance.frame?.maskThresholdMin ?? 0.5
    readonly property real frameMaskSpreadAtMin: ConfigFiles.Config.appearance.frame?.maskSpreadAtMin ?? 1.0

    readonly property color cutoutBlack: ConfigFiles.Config.appearance.cutoutBlack || "#000000"

    readonly property bool shadowEnabled: ConfigFiles.Config.appearance.shadow?.enabled ?? true
    readonly property real shadowOpacity: ConfigFiles.Config.appearance.shadow?.opacity ?? 0.18
    readonly property real shadowBlur: ConfigFiles.Config.appearance.shadow?.blur ?? 24
    readonly property real shadowOffsetY: ConfigFiles.Config.appearance.shadow?.offsetY ?? 6
}
