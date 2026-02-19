import QtQuick
import QtQuick.Layouts

import "../../config" as Config
import "../../utils"
import "./" as Controls

/*
  ExpandablePowerMenu
  Single power trigger that expands/collapses the full power action list.
*/
Item {
    id: root

    required property string iconFont

    property int itemHeight: Math.max(36, Math.round(Config.Appearance.fontSizeMedium * 2.4))
    property int spacing: 8
    property bool expanded: false
    property bool forceCollapsed: false

    signal actionTriggered(string actionId)

    readonly property int triggerHeight: root.itemHeight
    readonly property int expandedContentHeight: powerMenu.implicitHeight
    readonly property bool pressed: toggleArea.pressed
    readonly property color activeColor: Config.Palette.color("primary")
    readonly property color inactiveColor: Config.Palette.color("surface_container")
    readonly property color activeTextColor: Config.Palette.color("on_primary")
    readonly property color inactiveTextColor: Config.Palette.color("on_surface")
    readonly property color inactiveIconColor: Config.Palette.color("on_surface_variant")
    property real revealHeight: root.expanded ? root.expandedContentHeight : 0

    implicitWidth: content.implicitWidth
    implicitHeight: root.triggerHeight + (revealHeight > 0 ? root.spacing : 0) + revealHeight

    onForceCollapsedChanged: {
        if (forceCollapsed) {
            root.expanded = false;
        }
    }

    Behavior on revealHeight {
        Anim {
            durationMs: Config.Motion.shellDuration
            curve: Config.Motion.shellCurve
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: revealHeight > 0 ? root.spacing : 0

        Rectangle {
            id: triggerButton

            Layout.fillWidth: true
            Layout.preferredHeight: root.triggerHeight
            radius: root.expanded ? Config.Appearance.radiusMedium : Math.round(root.triggerHeight / 2)
            color: root.expanded ? root.activeColor : root.inactiveColor
            scale: root.pressed ? 0.96 : 1

            Behavior on radius {
                Anim {
                    durationMs: Config.Motion.shortDuration
                    curve: Config.Motion.standardCurve
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Config.Motion.shortDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Motion.standardCurve
                }
            }

            Behavior on scale {
                Anim {
                    durationMs: Config.Motion.shortDuration
                    curve: Config.Motion.standardCurve
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "power_settings_new"
                    font.family: root.iconFont
                    font.pixelSize: Math.round(root.triggerHeight * 0.5)
                    font.weight: Font.Medium
                    color: root.expanded ? root.activeTextColor : root.inactiveIconColor
                    verticalAlignment: Text.AlignVCenter
                    Layout.preferredWidth: implicitWidth
                }

                Text {
                    text: "Session"
                    font.family: Config.Appearance.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: Config.Appearance.fontSizeMedium
                    color: root.expanded ? root.activeTextColor : root.inactiveTextColor
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: toggleArea
                anchors.fill: parent
                onClicked: root.expanded = !root.expanded
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.revealHeight
            clip: true

            Controls.PowerMenu {
                id: powerMenu

                width: parent.width
                iconFont: root.iconFont
                spacing: root.spacing
                itemHeight: root.itemHeight
                onActionTriggered: actionId => {
                    root.expanded = false;
                    root.actionTriggered(actionId);
                }
            }
        }
    }
}
