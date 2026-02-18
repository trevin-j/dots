import QtQuick
import QtQuick.Shapes
import Quickshell

import "../../config" as Config
import "../../services" as Services

/*
  AttachedBubbleLayer
  Draws attached bubble backgrounds for registered FrameWrapper items.
*/
Item {
    id: root

    required property ShellScreen screen
    required property real frameInnerX
    required property real frameInnerY
    required property real frameInnerWidth
    required property real frameInnerHeight

    property real bubbleRounding: Config.Appearance.bubbleRounding
    property real bubblePadding: Config.Appearance.bubblePadding

    function clampRadius(value, widthValue, heightValue) {
        return Math.max(0, Math.min(value, widthValue / 2, heightValue / 2));
    }

    function edgeClamp(radiusValue, insetA, insetB) {
        return Math.max(0, Math.min(radiusValue, insetA, insetB));
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        Repeater {
            model: Services.FrameRegistry.wrappers

            delegate: ShapePath {
                required property var modelData

                readonly property Item wrapper: modelData
                readonly property bool sameScreen: wrapper && wrapper.screen === root.screen
                readonly property bool active: sameScreen && wrapper.bubbleVisible

                readonly property real screenOffsetX: root.screen.x
                readonly property real screenOffsetY: root.screen.y
                readonly property real paddingValue: wrapper ? wrapper.bubblePadding : root.bubblePadding
                readonly property real rawX: wrapper ? wrapper.globalX - screenOffsetX : 0
                readonly property real rawY: wrapper ? wrapper.globalY - screenOffsetY : 0
                readonly property real rawWidth: wrapper ? wrapper.width : 0
                readonly property real rawHeight: wrapper ? wrapper.height : 0

                readonly property real baseX: rawX - paddingValue
                readonly property real baseY: rawY - paddingValue
                readonly property real baseWidth: rawWidth + paddingValue * 2
                readonly property real baseHeight: rawHeight + paddingValue * 2

                readonly property string attachEdge: wrapper ? wrapper.attachEdge : ""
                readonly property var attachEdges: attachEdge ? attachEdge.split(/[-\s]+/) : []
                readonly property bool attachTop: attachEdges.indexOf("top") !== -1
                readonly property bool attachBottom: attachEdges.indexOf("bottom") !== -1
                readonly property bool attachLeft: attachEdges.indexOf("left") !== -1
                readonly property bool attachRight: attachEdges.indexOf("right") !== -1
                readonly property real frameLeft: root.frameInnerX
                readonly property real frameTop: root.frameInnerY
                readonly property real frameRight: root.frameInnerX + root.frameInnerWidth
                readonly property real frameBottom: root.frameInnerY + root.frameInnerHeight

                readonly property real rectX: {
                    if (attachLeft) {
                        return Math.min(baseX, frameLeft);
                    }
                    return baseX;
                }
                readonly property real rectY: {
                    if (attachTop) {
                        return Math.min(baseY, frameTop);
                    }
                    return baseY;
                }
                readonly property real rectWidth: {
                    if (attachRight) {
                        const delta = Math.max(0, frameRight - (baseX + baseWidth));
                        return baseWidth + delta;
                    }
                    if (attachLeft) {
                        return baseWidth + Math.max(0, baseX - frameLeft);
                    }
                    return baseWidth;
                }
                readonly property real rectHeight: {
                    if (attachBottom) {
                        const delta = Math.max(0, frameBottom - (baseY + baseHeight));
                        return baseHeight + delta;
                    }
                    if (attachTop) {
                        return baseHeight + Math.max(0, baseY - frameTop);
                    }
                    return baseHeight;
                }

                readonly property real roundingBase: root.clampRadius(
                    wrapper ? wrapper.bubbleRounding : root.bubbleRounding,
                    rectWidth,
                    rectHeight
                )

                readonly property real insetLeft: rectX - frameLeft
                readonly property real insetTop: rectY - frameTop
                readonly property real insetRight: frameRight - (rectX + rectWidth)
                readonly property real insetBottom: frameBottom - (rectY + rectHeight)

                readonly property real radiusTopLeft: root.edgeClamp(roundingBase, insetLeft, insetTop)
                readonly property real radiusTopRight: root.edgeClamp(roundingBase, insetRight, insetTop)
                readonly property real radiusBottomRight: root.edgeClamp(roundingBase, insetRight, insetBottom)
                readonly property real radiusBottomLeft: root.edgeClamp(roundingBase, insetLeft, insetBottom)

                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: active ? Config.Palette.color(wrapper.bubbleColorRole) : "transparent"

                startX: rectX + radiusTopLeft
                startY: rectY

                PathLine { x: rectX + rectWidth - radiusTopRight; y: rectY }
                PathArc {
                    x: rectX + rectWidth
                    y: rectY + radiusTopRight
                    radiusX: radiusTopRight
                    radiusY: radiusTopRight
                    direction: PathArc.Clockwise
                }
                PathLine { x: rectX + rectWidth; y: rectY + rectHeight - radiusBottomRight }
                PathArc {
                    x: rectX + rectWidth - radiusBottomRight
                    y: rectY + rectHeight
                    radiusX: radiusBottomRight
                    radiusY: radiusBottomRight
                    direction: PathArc.Clockwise
                }
                PathLine { x: rectX + radiusBottomLeft; y: rectY + rectHeight }
                PathArc {
                    x: rectX
                    y: rectY + rectHeight - radiusBottomLeft
                    radiusX: radiusBottomLeft
                    radiusY: radiusBottomLeft
                    direction: PathArc.Clockwise
                }
                PathLine { x: rectX; y: rectY + radiusTopLeft }
                PathArc {
                    x: rectX + radiusTopLeft
                    y: rectY
                    radiusX: radiusTopLeft
                    radiusY: radiusTopLeft
                    direction: PathArc.Clockwise
                }
            }
        }
    }
}
