import QtQuick
import QtQuick.Layouts

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
    readonly property int preloadItems: Config.Config.controlCenter?.wallpaper?.preloadItems ?? 6
    readonly property var wallpapers: Services.WallpaperService.wallpapers

    property int currentIndex: -1

    signal applyRequested(string path)

    function initializeSelection() {
        if (root.wallpapers.length <= 0) {
            root.currentIndex = -1;
            return;
        }
        const initial = Services.WallpaperService.selectedIndexForCurrent();
        root.currentIndex = Math.max(0, initial);
        listView.positionViewAtIndex(root.currentIndex, ListView.Center);
    }

    function moveSelection(delta) {
        const next = Services.WallpaperService.moveSelection(root.currentIndex, delta);
        if (next < 0 || next === root.currentIndex) {
            return;
        }
        root.currentIndex = next;
    }

    function selectIndex(index) {
        const clamped = Services.WallpaperService.moveSelection(index, 0);
        if (clamped < 0) {
            return;
        }
        root.currentIndex = clamped;
    }

    function applyCurrent() {
        if (root.currentIndex < 0 || root.currentIndex >= root.wallpapers.length) {
            return;
        }
        root.applyRequested(root.wallpapers[root.currentIndex]);
    }

    onOpenChanged: {
        if (root.open) {
            Services.WallpaperService.refreshWallpapers();
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

    onCurrentIndexChanged: {
        if (root.currentIndex < 0) {
            return;
        }
        listView.positionViewAtIndex(root.currentIndex, ListView.Center);
    }

    Timer {
        id: focusTimer

        interval: 0
        repeat: false
        onTriggered: root.forceActiveFocus()
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
            spacing: root.itemSpacing
            model: root.wallpapers
            interactive: false
            currentIndex: root.currentIndex
            cacheBuffer: Math.max(600, root.selectedItemHeight * root.preloadItems)
            preferredHighlightBegin: height * 0.5 - root.selectedItemHeight * 0.5
            preferredHighlightEnd: height * 0.5 + root.selectedItemHeight * 0.5
            highlightRangeMode: ListView.StrictlyEnforceRange
            snapMode: ListView.SnapToItem

            delegate: Item {
                id: delegateRoot

                readonly property bool selected: index === root.currentIndex
                readonly property real selectedScale: selected ? 1 : 0.84
                readonly property real selectedOpacity: selected ? 1 : 0.7

                width: listView.width
                height: selected ? root.selectedItemHeight : root.itemHeight
                scale: selectedScale
                opacity: selectedOpacity

                Behavior on height {
                    Anim {
                        durationMs: Config.Motion.expressiveDefaultSpatialDuration
                        curve: Config.Motion.expressiveDefaultSpatialCurve
                    }
                }

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

                Rectangle {
                    anchors.centerIn: parent
                    width: selected ? root.selectedThumbnailWidth : root.thumbnailWidth
                    height: parent.height
                    radius: Config.Appearance.radiusMedium
                    color: selected ? Config.Palette.color("primary_container") : Config.Palette.color("surface_container_high")
                    border.width: selected ? 2 : 1
                    border.color: selected ? Config.Palette.color("primary") : Config.Palette.color("outline_variant")
                    clip: true

                    Behavior on width {
                        Anim {
                            durationMs: Config.Motion.expressiveDefaultSpatialDuration
                            curve: Config.Motion.expressiveDefaultSpatialCurve
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
                        anchors.fill: parent
                        source: modelData
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: selected ? root.selectedThumbnailWidth : root.thumbnailWidth
                        sourceSize.height: selected ? root.selectedItemHeight : root.itemHeight
                        smooth: true
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Math.max(26, Math.round(root.contentPadding * 1.8))
                        color: selected ? Config.Palette.color("primary") : Config.Palette.color("scrim")
                        opacity: selected ? 0.28 : 0.38

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            text: {
                                const pieces = String(modelData || "").split("/");
                                return pieces.length > 0 ? pieces[pieces.length - 1] : "";
                            }
                            elide: Text.ElideRight
                            font.family: Config.Appearance.fontFamily
                            font.weight: Config.Appearance.fontWeight
                            font.pixelSize: Math.max(10, Math.round(Config.Appearance.fontSizeSmall))
                            color: selected ? Config.Palette.color("on_primary_container") : Config.Palette.color("on_surface")
                        }
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
        target: root
        onWheel: event => {
            if (!root.open || root.wallpapers.length <= 0) {
                return;
            }
            const delta = event.angleDelta.y;
            if (delta > 0) {
                root.moveSelection(-1);
            } else if (delta < 0) {
                root.moveSelection(1);
            }
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
