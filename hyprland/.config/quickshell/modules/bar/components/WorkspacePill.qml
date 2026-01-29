import QtQuick
import QtQuick.Layouts

import "../../../config" as Config
import "./"

Item {
    id: root

    required property int workspaceId
    required property string label
    required property bool active
    required property bool occupied
    required property bool vertical

    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight

    WorkspaceIndicator {
        id: indicator

        workspaceId: root.workspaceId
        active: root.active
        occupied: root.occupied
        vertical: root.vertical

        Text {
            id: labelText

            anchors.centerIn: parent
            text: root.label
            color: active
                ? Config.Palette.color("on_primary")
                : Config.Palette.color("on_surface")
            font.family: Config.Appearance.fontFamily
            font.weight: Config.Appearance.fontWeight
            font.pixelSize: Config.Appearance.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        contentWidth: Math.max(12, labelText.paintedWidth + indicator.layoutHorizontalPadding * 2)
        contentHeight: Math.max(12, labelText.paintedHeight + indicator.layoutVerticalPadding * 2)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: indicator.hovered = true
            onExited: indicator.hovered = false
        }
    }
}
