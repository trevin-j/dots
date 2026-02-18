import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import "../../../config" as Config

/*
  StatusPill
  Compact status row used as quick settings trigger.
*/
Rectangle {
    id: root

    required property int barHeight
    required property int spacing
    required property string materialFont
    required property int iconSize
    required property int horizontalPadding
    required property int verticalPadding
    required property var viewModel

    radius: Config.Appearance.radiusMedium
    color: Config.Palette.color("surface_container")

    PwObjectTracker {
        objects: [root.viewModel.defaultSink]
    }

    implicitWidth: contentRow.implicitWidth + root.horizontalPadding * 2
    implicitHeight: Math.max(contentRow.implicitHeight + root.verticalPadding * 2, Math.round(root.barHeight * 0.6))

    RowLayout {
        id: contentRow

        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        anchors.topMargin: root.verticalPadding
        anchors.bottomMargin: root.verticalPadding
        spacing: root.spacing

        Text {
            text: root.viewModel.wifiIconName
            color: Config.Palette.color("on_surface")
            font.family: root.materialFont
            font.pixelSize: root.iconSize
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter

            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.viewModel.volumeIconName
            color: Config.Palette.color("on_surface")
            font.family: root.materialFont
            font.pixelSize: root.iconSize
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter

            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.viewModel.batteryIconName
            color: root.viewModel.batteryTextColor
            font.family: root.materialFont
            font.pixelSize: root.iconSize
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter

            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.viewModel.batteryPercentLabel
            color: root.viewModel.batteryTextColor
            font.family: Config.Appearance.fontFamily
            font.weight: Config.Appearance.fontWeight
            font.pixelSize: Config.Appearance.fontSizeMedium
            verticalAlignment: Text.AlignVCenter

            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.viewModel.dateText
            color: Config.Palette.color("on_surface")
            font.family: Config.Appearance.fontFamily
            font.weight: Config.Appearance.fontWeight
            font.pixelSize: Config.Appearance.fontSizeMedium
            verticalAlignment: Text.AlignVCenter

            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.viewModel.timeText
            color: Config.Palette.color("on_surface")
            font.family: Config.Appearance.fontFamily
            font.weight: Config.Appearance.fontWeight
            font.pixelSize: Config.Appearance.fontSizeMedium
            verticalAlignment: Text.AlignVCenter

            Layout.alignment: Qt.AlignVCenter
        }
    }
}
