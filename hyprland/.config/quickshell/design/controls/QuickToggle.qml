import QtQuick
import QtQuick.Layouts

import "../../config" as Config
import "../../utils"

/*
  QuickToggle
  Toggle button for quick settings.
  Required properties: label, icon, active, iconFont.
*/
Item {
    id: root

    required property string label
    required property string icon
    required property bool active
    required property string iconFont
    property string secondaryText: ""

    property bool enabled: true
    signal toggled(bool next)

    readonly property color activeColor: Config.Palette.color("primary")
    readonly property color inactiveColor: Config.Palette.color("surface_container")
    readonly property color activeTextColor: Config.Palette.color("on_primary")
    readonly property color inactiveTextColor: Config.Palette.color("on_surface")
    readonly property color inactiveIconColor: Config.Palette.color("on_surface_variant")

    readonly property bool pressed: toggleArea.pressed
    readonly property bool hasSecondary: secondaryText !== ""

    implicitWidth: Math.max(140, rowContent.implicitWidth + Math.max(12, Math.round(background.height * 0.3)) * 2)
    implicitHeight: Math.max(48, Math.round(Config.Appearance.fontSizeMedium * (hasSecondary ? 3.6 : 2.9)))

    Rectangle {
        id: background

        anchors.fill: parent
        radius: root.active ? Config.Appearance.radiusMedium : height / 2
        color: root.active ? root.activeColor : root.inactiveColor
        opacity: root.enabled ? 1 : 0.6
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
            id: rowContent

            anchors.fill: parent
            anchors.leftMargin: Math.max(12, Math.round(background.height * 0.3))
            anchors.rightMargin: Math.max(12, Math.round(background.height * 0.3))
            spacing: Math.max(8, Math.round(background.height * 0.22))

            Text {
                text: root.icon
                font.family: root.iconFont
                font.pixelSize: Math.round(background.height * 0.5)
                font.weight: Font.Medium
                color: root.active ? root.activeTextColor : root.inactiveIconColor
                verticalAlignment: Text.AlignVCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight

                Text {
                    text: root.label
                    font.family: Config.Appearance.fontFamily
                    font.weight: Config.Appearance.fontWeight
                    font.pixelSize: Config.Appearance.fontSizeMedium
                    color: root.active ? root.activeTextColor : root.inactiveTextColor
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }

                Text {
                    visible: root.secondaryText !== ""
                    text: root.secondaryText
                    font.family: Config.Appearance.fontFamily
                    font.weight: Config.Appearance.fontWeight
                    font.pixelSize: Math.max(10, Math.round(Config.Appearance.fontSizeSmall))
                    color: root.active ? root.activeTextColor : root.inactiveIconColor
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
            }
        }
    }

    MouseArea {
        id: toggleArea
        anchors.fill: parent
        hoverEnabled: false
        enabled: root.enabled
        onClicked: root.toggled(!root.active)
    }
}
