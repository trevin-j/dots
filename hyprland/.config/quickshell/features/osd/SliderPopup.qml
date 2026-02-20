import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../config" as Config
import "../../design/primitives" as Primitives
import "../../utils"

/*
  SliderPopup
  Reusable OSD popup with icon and horizontal slider.
  Required properties: active, iconName, level, style.
*/
PanelWindow {
    id: root

    required property bool active
    required property string iconName
    required property real level
    required property var style

    property bool interacting: false
    property string bubbleColorRole: "surface"
    property string attachEdge: "bottom"

    signal levelSet(real value)

    readonly property int popupWidth: style?.width ?? 280
    readonly property int popupPadding: style?.padding ?? 16
    readonly property int popupSpacing: style?.spacing ?? 12
    readonly property int iconSize: style?.iconSize ?? 18
    readonly property int trackHeight: style?.trackHeight ?? 6
    readonly property int thumbSize: style?.thumbSize ?? 16
    readonly property real cornerRadius: Config.Appearance.radiusLarge
    readonly property string iconFont: Config.Appearance.iconFontFamily
    readonly property real normalizedLevel: Math.min(1, Math.max(0, level))

    function setLevelFromX(positionX) {
        const trackWidth = trackBackground.width;
        if (trackWidth <= 0) {
            return;
        }
        const clamped = Math.min(1, Math.max(0, positionX / trackWidth));
        root.levelSet(clamped);
    }

    anchors.bottom: true
    margins.bottom: 0
    exclusiveZone: 0

    focusable: false
    visible: true
    color: "transparent"
    surfaceFormat.opaque: false

    implicitWidth: popupWrapper.implicitWidth
    implicitHeight: popupContainer.implicitHeight

    mask: Region {
        item: popupWrapper
    }

    Primitives.SurfaceShadow {
        source: popupWrapper
        enabled: Config.Appearance.shadowEnabled && (root.active || popupWrapper.implicitHeight > 0)
    }

    Primitives.FrameWrapper {
        id: popupWrapper

        screen: root.screen
        attachEdge: root.attachEdge
        active: root.active
        bubbleColorRole: root.bubbleColorRole

        width: implicitWidth
        height: implicitHeight
        implicitWidth: root.popupWidth + root.cornerRadius * 2
        implicitHeight: 0
        clip: true
        visible: root.active || implicitHeight > 0

        anchors.bottom: parent.bottom

        states: State {
            name: "open"
            when: root.active

            PropertyChanges {
                popupWrapper.implicitHeight: popupContainer.implicitHeight
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "open"

                Anim {
                    target: popupWrapper
                    property: "implicitHeight"
                    durationMs: Config.Motion.shellDuration
                    curve: Config.Motion.shellCurve
                }
            },
            Transition {
                from: "open"
                to: ""

                Anim {
                    target: popupWrapper
                    property: "implicitHeight"
                    durationMs: Config.Motion.shortDuration
                    curve: Config.Motion.standardCurve
                }
            }
        ]

        Rectangle {
            id: popupContainer

            width: root.popupWidth
            x: root.cornerRadius
            anchors.bottom: parent.bottom
            radius: root.cornerRadius
            color: Config.Palette.color(root.bubbleColorRole)
            implicitHeight: contentRow.implicitHeight + root.popupPadding * 2

            Rectangle {
                width: root.cornerRadius
                height: root.cornerRadius
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                color: parent.color
            }

            Rectangle {
                width: root.cornerRadius
                height: root.cornerRadius
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: parent.color
            }

            RowLayout {
                id: contentRow

                anchors.fill: parent
                anchors.leftMargin: root.popupPadding
                anchors.topMargin: root.popupPadding
                anchors.bottomMargin: root.popupPadding
                anchors.rightMargin: root.popupPadding + 8
                spacing: root.popupSpacing

                Text {
                    text: root.iconName
                    color: Config.Palette.color("on_surface")
                    font.family: root.iconFont
                    font.pixelSize: root.iconSize
                    font.weight: Font.Medium
                    verticalAlignment: Text.AlignVCenter

                    Layout.preferredWidth: implicitWidth
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    id: sliderTrack

                    implicitHeight: Math.max(root.thumbSize, root.trackHeight)
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        id: trackBackground

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: root.trackHeight
                        radius: height / 2
                        color: Config.Palette.color("surface_container_low")
                    }

                    Rectangle {
                        id: trackFill

                        anchors.left: trackBackground.left
                        anchors.verticalCenter: trackBackground.verticalCenter
                        height: trackBackground.height
                        radius: trackBackground.radius
                        width: trackBackground.width * root.normalizedLevel
                        color: Config.Palette.color("primary")

                        Behavior on width {
                            enabled: !root.interacting
                            Anim {
                                durationMs: Config.Motion.mediumDuration
                                curve: Config.Motion.standardCurve
                            }
                        }
                    }

                    Rectangle {
                        id: thumb

                        width: root.thumbSize
                        height: root.thumbSize
                        radius: width / 2
                        color: Config.Palette.color("primary")
                        anchors.verticalCenter: trackBackground.verticalCenter
                        x: trackBackground.x + trackBackground.width * root.normalizedLevel - width / 2

                        Behavior on x {
                            enabled: !root.interacting
                            Anim {
                                durationMs: Config.Motion.mediumDuration
                                curve: Config.Motion.standardCurve
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onPressed: {
                            root.interacting = true;
                            root.setLevelFromX(mouse.x);
                        }

                        onPositionChanged: {
                            if (pressed) {
                                root.setLevelFromX(mouse.x);
                            }
                        }

                        onReleased: root.interacting = false
                        onCanceled: root.interacting = false
                    }
                }
            }
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: popupContainer.color
            mirrorX: true
            mirrorY: true
            anchors.right: popupContainer.left
            anchors.bottom: popupContainer.bottom
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: popupContainer.color
            mirrorY: true
            anchors.left: popupContainer.right
            anchors.bottom: popupContainer.bottom
        }
    }
}
