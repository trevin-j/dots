import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "../../../config" as Config
import "../../../services" as Services
import "../../../utils"

/*
  WallpaperSelectorPanel
  Vertical wallpaper carousel with keyboard, wheel, and click selection/apply.
  Required properties: open, panelWidth.
*/
Item {
    id: root

    required property bool open
    required property int panelWidth

    readonly property int contentPadding: Config.Config.controlCenter?.size?.padding ?? 16
    readonly property int itemSpacing: Config.Config.controlCenter?.wallpaper?.itemSpacing ?? 12
    readonly property int itemHeight: Config.Config.controlCenter?.wallpaper?.itemHeight ?? 132
    readonly property int selectedItemHeight: Config.Config.controlCenter?.wallpaper?.selectedItemHeight ?? 186
    readonly property int thumbnailWidth: Config.Config.controlCenter?.wallpaper?.thumbnailWidth ?? 284
    readonly property int selectedThumbnailWidth: Config.Config.controlCenter?.wallpaper?.selectedThumbnailWidth ?? 292
    readonly property int gapNearSelected: Config.Config.controlCenter?.wallpaper?.gapNearSelected ?? 8
    readonly property int gapRegular: Config.Config.controlCenter?.wallpaper?.gapRegular ?? 2
    readonly property int preloadItems: Config.Config.controlCenter?.wallpaper?.preloadItems ?? 6
    readonly property var wallpapers: Services.WallpaperService.wallpapers
    readonly property int decodeWidth: Math.max(root.thumbnailWidth, root.selectedThumbnailWidth)
    readonly property int decodeHeight: Math.max(root.itemHeight, root.selectedItemHeight)
    readonly property real selectedScale: 1
    readonly property real unselectedScale: Math.max(0.1, Math.min(1, root.itemHeight / Math.max(1, root.selectedItemHeight)))

    property int currentIndex: -1
    property real wheelAccumulator: 0

    signal applyRequested(string path)

    function initializeSelection() {
        if (root.wallpapers.length <= 0) {
            root.currentIndex = -1;
            return;
        }
        const initial = Services.WallpaperService.selectedIndexForCurrent();
        root.setCurrentIndex(Math.max(0, initial), true);
    }

    function moveSelection(delta) {
        const next = Services.WallpaperService.moveSelection(root.currentIndex, delta);
        if (next < 0 || next === root.currentIndex) {
            return;
        }
        root.setCurrentIndex(next, false);
    }

    function selectIndex(index) {
        const clamped = Services.WallpaperService.moveSelection(index, 0);
        if (clamped < 0) {
            return;
        }
        root.setCurrentIndex(clamped, false);
    }

    function applyCurrent() {
        if (root.currentIndex < 0 || root.currentIndex >= root.wallpapers.length) {
            return;
        }
        root.applyRequested(root.wallpapers[root.currentIndex]);
    }

    function queueWheelDelta(deltaY) {
        if (!Number.isFinite(deltaY) || deltaY === 0) {
            return;
        }
        root.wheelAccumulator += deltaY;
        root.flushWheelAccumulator();
        wheelResetTimer.restart();
    }

    function delegateGapFor(index) {
        if (root.currentIndex < 0 || index < 0) {
            return root.gapRegular;
        }
        return (index === root.currentIndex || Math.abs(index - root.currentIndex) === 1)
            ? root.gapNearSelected
            : root.gapRegular;
    }

    function delegateVisualHeightFor(index) {
        if (index === root.currentIndex) {
            return root.selectedItemHeight;
        }
        return root.itemHeight;
    }

    function delegateHeightFor(index) {
        return root.delegateVisualHeightFor(index) + root.delegateGapFor(index);
    }

    function flushWheelAccumulator() {
        const threshold = 48;
        let stepped = false;
        while (Math.abs(root.wheelAccumulator) >= threshold) {
            if (root.wheelAccumulator > 0) {
                root.moveSelection(-1);
                root.wheelAccumulator -= threshold;
            } else {
                root.moveSelection(1);
                root.wheelAccumulator += threshold;
            }
            stepped = true;
        }
        if (stepped) {
            wheelResetTimer.restart();
        }
    }

    function clampContentY(value) {
        const maxY = Math.max(0, listView.contentHeight - listView.height);
        return Math.max(0, Math.min(maxY, value));
    }

    function targetContentYForIndex(index) {
        let y = 0;
        for (let row = 0; row < index; row += 1) {
            y += root.delegateHeightFor(row);
        }
        const centerY = y + (root.delegateHeightFor(index) * 0.5);
        return root.clampContentY(centerY - (listView.height * 0.5));
    }

    function setCurrentIndex(index, immediate) {
        root.currentIndex = index;
        if (index < 0) {
            return;
        }
        const target = root.targetContentYForIndex(index);
        if (immediate) {
            scrollAnimation.stop();
            listView.contentY = target;
            return;
        }
        scrollAnimation.stop();
        scrollAnimation.from = listView.contentY;
        scrollAnimation.to = target;
        scrollAnimation.start();
    }

    onOpenChanged: {
        if (root.open) {
            if (!Services.WallpaperService.ready || Services.WallpaperService.wallpapers.length <= 0) {
                Services.WallpaperService.refreshWallpapers();
            }
            root.initializeSelection();
            focusTimer.restart();
        }
    }

    onWallpapersChanged: {
        if (!root.open) {
            return;
        }
        root.initializeSelection();
    }

    Timer {
        id: focusTimer

        interval: 0
        repeat: false
        onTriggered: root.forceActiveFocus()
    }

    NumberAnimation {
        id: scrollAnimation

        target: listView
        property: "contentY"
        duration: Config.Motion.expressiveDefaultSpatialDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Motion.expressiveDefaultSpatialCurve
    }

    Timer {
        id: wheelResetTimer

        interval: 72
        repeat: false
        onTriggered: root.wheelAccumulator = 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.contentPadding
        spacing: Math.max(8, Math.round(root.itemSpacing * 0.7))

        Text {
            text: "Wallpapers"
            font.family: Config.Appearance.fontFamily
            font.weight: Font.DemiBold
            font.pixelSize: Config.Appearance.fontSizeLarge
            color: Config.Palette.color("on_surface")
            Layout.fillWidth: true
        }

        Text {
            text: Services.WallpaperService.loading
                ? "Scanning..."
                : (root.wallpapers.length > 0 ? `${root.wallpapers.length} images` : "No wallpapers found")
            font.family: Config.Appearance.fontFamily
            font.weight: Config.Appearance.fontWeight
            font.pixelSize: Config.Appearance.fontSizeSmall
            color: Config.Palette.color("on_surface_variant")
            Layout.fillWidth: true
        }

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            model: root.wallpapers
            interactive: false
            currentIndex: root.currentIndex
            reuseItems: true
            cacheBuffer: Math.max(root.selectedItemHeight * 3, root.selectedItemHeight * root.preloadItems)
            highlightRangeMode: ListView.NoHighlightRange
            snapMode: ListView.NoSnap

            onHeightChanged: {
                if (root.currentIndex >= 0) {
                    listView.contentY = root.targetContentYForIndex(root.currentIndex);
                }
            }

            delegate: Item {
                id: delegateRoot

                readonly property bool selected: index === root.currentIndex
                readonly property real cardScale: selected ? root.selectedScale : root.unselectedScale
                readonly property real cardOpacity: selected ? 1 : 0.76

                width: listView.width
                height: root.delegateHeightFor(index)

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.selectedThumbnailWidth
                    height: root.selectedItemHeight
                    scale: delegateRoot.cardScale
                    opacity: delegateRoot.cardOpacity
                    transformOrigin: Item.Right
                    radius: Config.Appearance.radiusLarge
                    antialiasing: true
                    color: selected ? Config.Palette.color("primary_container") : Config.Palette.color("surface_container_high")
                    border.width: selected ? 2 : 1
                    border.color: selected ? Config.Palette.color("primary") : Config.Palette.color("outline_variant")
                    clip: true

                    Behavior on scale {
                        Anim {
                            durationMs: Config.Motion.expressiveDefaultSpatialDuration
                            curve: Config.Motion.expressiveDefaultSpatialCurve
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            durationMs: Config.Motion.expressiveEffectsDuration
                            curve: Config.Motion.expressiveEffectsCurve
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.Motion.expressiveEffectsDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Motion.expressiveEffectsCurve
                        }
                    }

                    Image {
                        id: wallpaperImage

                        anchors.fill: parent
                        source: modelData
                        asynchronous: true
                        cache: true
                        mipmap: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: root.decodeWidth
                        sourceSize.height: root.decodeHeight
                        smooth: true
                        visible: false
                    }

                    Rectangle {
                        id: imageMask

                        anchors.fill: parent
                        radius: parent.radius
                        color: "black"
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: wallpaperImage
                        maskSource: imageMask
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (delegateRoot.selected) {
                                root.applyCurrent();
                            } else {
                                root.selectIndex(index);
                            }
                        }
                    }
                }
            }
        }
    }

    WheelHandler {
        target: listView
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (!root.open || root.wallpapers.length <= 0) {
                return;
            }
            let delta = 0;
            if (event.pixelDelta.y !== 0 || event.pixelDelta.x !== 0) {
                delta = Math.abs(event.pixelDelta.y) >= Math.abs(event.pixelDelta.x)
                    ? event.pixelDelta.y
                    : event.pixelDelta.x;
            } else {
                delta = Math.abs(event.angleDelta.y) >= Math.abs(event.angleDelta.x)
                    ? event.angleDelta.y
                    : event.angleDelta.x;
                delta = (delta / 120) * 48;
            }
            root.queueWheelDelta(delta);
            event.accepted = true;
        }
    }

    Keys.onPressed: event => {
        if (!root.open || root.wallpapers.length <= 0) {
            return;
        }
        if (event.key === Qt.Key_Up) {
            root.moveSelection(-1);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Down) {
            root.moveSelection(1);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applyCurrent();
            event.accepted = true;
        }
    }
}
