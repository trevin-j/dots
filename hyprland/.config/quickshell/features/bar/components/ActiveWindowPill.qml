import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import "../../../config" as Config
import "../../../utils" as Utils
import "../models" as BarModels

/*
  ActiveWindowPill
  Shows the current active application icon and name.
  Required properties: screen (ShellScreen), barHeight (int).
*/
Item {
    id: root

    required property ShellScreen screen
    required property int barHeight

    readonly property int horizontalPadding: Config.Config.bar.size?.spacing || 8
    readonly property int iconSize: Math.max(16, Math.round(root.barHeight * 0.5))

    BarModels.ActiveWindowModel {
        id: model
        screen: root.screen
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    opacity: model.hasActiveWindow ? 1 : 0

    Behavior on opacity {
        Utils.Anim {
            durationMs: Config.Motion.mediumDuration
            curve: Config.Motion.standardCurve
        }
    }

    Rectangle {
        id: pill

        radius: Config.Appearance.radiusMedium
        color: Config.Palette.color("surface_container")

        implicitWidth: contentRow.implicitWidth + root.horizontalPadding * 2
        implicitHeight: root.barHeight

        Behavior on implicitWidth {
            Utils.Anim {
                durationMs: Config.Motion.longDuration
                curve: Config.Motion.emphasizedCurve
            }
        }

        RowLayout {
            id: contentRow

            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
            spacing: Math.round(root.horizontalPadding / 2)

            IconImage {
                id: appIcon

                implicitSize: root.iconSize
                source: model.iconSource
                visible: source !== ""
                asynchronous: true
                mipmap: true

                anchors.verticalCenter: parent.verticalCenter
                opacity: model.hasActiveWindow ? 1 : 0

                Behavior on opacity {
                    Utils.Anim {
                        durationMs: Config.Motion.shortDuration
                        curve: Config.Motion.standardCurve
                    }
                }
            }

            Text {
                id: titleText

                text: model.displayName
                color: Config.Palette.color("on_surface")
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeSmall
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
                opacity: model.hasActiveWindow ? 1 : 0

                Layout.fillWidth: true

                Behavior on opacity {
                    Utils.Anim {
                        durationMs: Config.Motion.shortDuration
                        curve: Config.Motion.standardCurve
                    }
                }
            }
        }
    }
}
