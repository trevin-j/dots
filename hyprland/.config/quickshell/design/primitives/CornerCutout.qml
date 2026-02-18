import QtQuick

/*
  CornerCutout
  Draws a square filled with color and subtracts a quarter-circle.
  Required properties: radius, fillColor.
*/
Canvas {
    id: root

    required property real radius
    required property color fillColor
    property bool mirrorX: false
    property bool mirrorY: false

    width: radius
    height: radius

    transform: Scale {
        xScale: root.mirrorX ? -1 : 1
        yScale: root.mirrorY ? -1 : 1
        origin.x: root.width / 2
        origin.y: root.height / 2
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = root.fillColor;
        ctx.fillRect(0, 0, width, height);
        ctx.globalCompositeOperation = "destination-out";
        ctx.beginPath();
        ctx.moveTo(width, height);
        ctx.arc(width, height, width, Math.PI, Math.PI * 1.5, false);
        ctx.closePath();
        ctx.fill();
        ctx.globalCompositeOperation = "source-over";
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onRadiusChanged: requestPaint()
}
