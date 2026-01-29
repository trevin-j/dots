import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../components" as Shared
import "../../config" as Config
import "../../services" as Services
import "../../utils"

/*!
  BrightnessPopup
  Popup slider that appears on brightness changes.
  Required properties: active.
*/
PanelWindow {
    id: root

    required property bool active

    readonly property real brightnessLevel: Services.BrightnessService.level

    readonly property int popupWidth: Config.Config.popouts?.brightness?.width ?? 280
    readonly property int popupPadding: Config.Config.popouts?.brightness?.padding ?? 16
    readonly property int popupSpacing: Config.Config.popouts?.brightness?.spacing ?? 12
    readonly property int iconSize: Config.Config.popouts?.brightness?.iconSize ?? 18
    readonly property int trackHeight: Config.Config.popouts?.brightness?.trackHeight ?? 6
    readonly property int thumbSize: Config.Config.popouts?.brightness?.thumbSize ?? 16
    readonly property real cornerRadius: Config.Appearance.radiusLarge

    readonly property string materialFont: "Material Symbols Rounded"

    property bool interacting: false

    function setBrightnessFromX(positionX) {
        const trackWidth = trackBackground.width;
        if (trackWidth <= 0) {
            return;
        }
        const rawValue = positionX / trackWidth;
        const clamped = Math.min(1, Math.max(0, rawValue));
        Services.BrightnessService.setLevel(clamped);
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

    Shared.FrameWrapper {
        id: popupWrapper

        screen: root.screen
        attachEdge: "bottom"
        active: root.active
        bubbleColorRole: "surface_container_high"

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
            color: Config.Palette.color("surface_container_high")

            implicitHeight: contentRow.implicitHeight + root.popupPadding * 2

            anchors.bottomMargin: 0

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
                anchors.rightMargin: root.popupPadding + 6
                spacing: root.popupSpacing

                Text {
                    id: brightnessIcon

                    text: "brightness_6"
                    color: Config.Palette.color("on_surface")
                    font.family: root.materialFont
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
                        width: trackBackground.width * Math.min(1, Math.max(0, root.brightnessLevel))
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
                        x: trackBackground.x + trackBackground.width * Math.min(1, Math.max(0, root.brightnessLevel)) - width / 2

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
                            root.setBrightnessFromX(mouse.x);
                        }

                        onPositionChanged: {
                            if (pressed) {
                                root.setBrightnessFromX(mouse.x);
                            }
                        }

                        onReleased: root.interacting = false
                        onCanceled: root.interacting = false
                    }
                }
            }
        }

        Shared.CornerCutout {
            id: leftCap

            visible: root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: popupContainer.color
            mirrorX: true
            mirrorY: true
            anchors.right: popupContainer.left
            anchors.bottom: popupContainer.bottom
        }

        Shared.CornerCutout {
            id: rightCap

            visible: root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: popupContainer.color
            mirrorY: true
            anchors.left: popupContainer.right
            anchors.bottom: popupContainer.bottom
        }
    }
}
