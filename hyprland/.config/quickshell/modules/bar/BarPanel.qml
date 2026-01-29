import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../components" as Shared
import "../../config" as Config
import "components"

// Bar panel window for a screen; requires panelScreen.
PanelWindow {
    id: root

    required property ShellScreen panelScreen

    readonly property string position: Config.Config.bar.position || "top"
    readonly property int thickness: Config.Config.bar.size?.thickness ?? 40
    readonly property int padding: Config.Config.bar.size?.padding ?? 10
    readonly property int margin: Config.Config.bar.size?.margin ?? 10
    readonly property int marginTop: Config.Config.bar.size?.marginTop ?? margin
    readonly property int marginBottom: Config.Config.bar.size?.marginBottom ?? margin
    readonly property int marginSide: Config.Config.bar.size?.marginSide ?? margin
    readonly property int spacing: Config.Config.bar.size?.spacing ?? 8
    readonly property int edgeMargin: position === "top"
        ? marginTop
        : position === "bottom"
            ? marginBottom
            : marginSide
    readonly property bool exclusive: Config.Config.bar.behavior?.exclusiveZone ?? true
    screen: root.panelScreen
    aboveWindows: true

    color: "transparent"
    surfaceFormat.opaque: false

    focusable: false

    anchors.top: position === "top"
    anchors.bottom: position === "bottom"
    anchors.left: position === "left" || position === "top" || position === "bottom"
    anchors.right: position === "right" || position === "top" || position === "bottom"

    margins.top: position === "top" ? marginTop : 0
    margins.bottom: position === "bottom" ? marginBottom : 0
    margins.left: position === "left" ? marginSide : 0
    margins.right: position === "right" ? marginSide : 0

    exclusiveZone: exclusive ? thickness + edgeMargin : 0

    readonly property real visualThickness: (position === "top" || position === "bottom")
        ? thickness + cornerRadius
        : thickness

    implicitWidth: (position === "left" || position === "right") ? thickness : 0
    implicitHeight: (position === "top" || position === "bottom") ? visualThickness : 0

    readonly property real cornerRadius: Math.min(Config.Appearance.radiusLarge, thickness * 0.5)
    readonly property color barColor: Config.Palette.color("surface")

    Item {
        id: background

        anchors.fill: parent
        Rectangle {
            id: barBase

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.thickness
            color: root.barColor
        }

        Shared.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            anchors.left: parent.left
            anchors.top: parent.top
        }

        Shared.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            mirrorX: true
            anchors.right: parent.right
            anchors.top: parent.top
        }

        Shared.CornerCutout {
            id: leftCap

            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: root.barColor
            anchors.left: parent.left
            anchors.top: barBase.bottom
        }

        Shared.CornerCutout {
            id: rightCap

            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: root.barColor
            mirrorX: true
            anchors.right: parent.right
            anchors.top: barBase.bottom
        }

        Item {
            id: barContainer

            anchors.left: barBase.left
            anchors.right: barBase.right
            anchors.top: barBase.top
            anchors.leftMargin: padding
            anchors.rightMargin: padding
            anchors.topMargin: padding
            height: barBase.height - padding * 2

            RowLayout {
                id: edgeRow

                anchors.fill: parent
                spacing: root.spacing

                RowLayout {
                    id: leftSection

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 0
                    Layout.fillHeight: true
                    spacing: root.spacing

                    Workspaces {
                        screen: root.panelScreen
                        vertical: position === "left" || position === "right"
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }

                RowLayout {
                    id: rightSection

                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillHeight: true
                    spacing: root.spacing

                    RightStatus {
                        barHeight: root.thickness - root.padding * 2
                        spacing: root.spacing
                        Layout.fillHeight: true
                    }
                }
            }

            Item {
                id: centerSection

                anchors.centerIn: parent
                height: parent.height
                width: centerRow.implicitWidth

                RowLayout {
                    id: centerRow

                    anchors.fill: parent
                    spacing: root.spacing

                    ActiveWindowPill {
                        screen: root.panelScreen
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
