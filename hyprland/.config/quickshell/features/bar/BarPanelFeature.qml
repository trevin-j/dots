import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../config" as Config
import "../../design/primitives" as Primitives
import "./components" as BarComponents

/*
  BarPanelFeature
  Main bar panel composition for a single screen.
*/
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
        anchors.fill: parent

        Rectangle {
            id: barBase

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.thickness
            color: root.barColor
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            anchors.left: parent.left
            anchors.top: parent.top
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            mirrorX: true
            anchors.right: parent.right
            anchors.top: parent.top
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: root.barColor
            anchors.left: parent.left
            anchors.top: barBase.bottom
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: root.barColor
            mirrorX: true
            anchors.right: parent.right
            anchors.top: barBase.bottom
        }

        Item {
            anchors.left: barBase.left
            anchors.right: barBase.right
            anchors.top: barBase.top
            anchors.leftMargin: root.padding
            anchors.rightMargin: root.padding
            anchors.topMargin: root.padding
            height: barBase.height - root.padding * 2

            RowLayout {
                anchors.fill: parent
                spacing: root.spacing

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 0
                    Layout.fillHeight: true
                    spacing: root.spacing

                    BarComponents.Workspaces {
                        screen: root.panelScreen
                        vertical: root.position === "left" || root.position === "right"
                    }

                    BarComponents.ActiveWindowPill {
                        screen: root.panelScreen
                        Layout.fillHeight: true
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillHeight: true
                    spacing: root.spacing

                    BarComponents.RightStatus {
                        barHeight: root.thickness - root.padding * 2
                        spacing: root.spacing
                        screen: root.panelScreen
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
