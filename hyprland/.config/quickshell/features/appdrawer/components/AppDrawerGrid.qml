import QtQuick
import Quickshell.Widgets

import "../../../config" as Config

/*
  AppDrawerGrid
  Displays current app page as icon/name tiles in a fixed-column grid.
  Required properties: items, columns, tileHeight, iconSize.
*/
Item {
    id: root

    required property var items
    required property int columns
    required property int tileHeight
    required property int iconSize
    required property int tileSpacing
    required property var model
    required property int selectedPageIndex

    signal appActivated(string desktopId)

    readonly property var itemList: Array.isArray(items) ? items : []
    readonly property real tileWidth: Math.max(0, (width - (root.columns - 1) * root.tileSpacing) / root.columns)

    Repeater {
        model: root.itemList

        delegate: Item {
            id: tileRoot

            required property int index
            required property var modelData

            readonly property int row: Math.floor(index / root.columns)
            readonly property int column: index % root.columns
            readonly property string desktopId: modelData.desktopId || ""
            readonly property string iconName: modelData.iconName || ""
            readonly property string appName: modelData.name || desktopId
            readonly property string iconSource: root.model.iconSourceFor(iconName)
            readonly property real iconTopMargin: Math.max(6, Math.round(root.tileHeight * 0.08))
            readonly property real textTopMargin: Math.max(6, Math.round(root.tileHeight * 0.14))
            readonly property bool selected: index === root.selectedPageIndex

            x: column * (root.tileWidth + root.tileSpacing)
            y: row * (root.tileHeight + root.tileSpacing)
            width: root.tileWidth
            height: root.tileHeight

            Rectangle {
                id: tileBackground

                anchors.fill: parent
                radius: Config.Appearance.radiusMedium
                color: tileRoot.selected
                    ? Config.Palette.color("secondary_container")
                    : (mouseArea.pressed
                        ? Config.Palette.color("surface_container_high")
                        : "transparent")
                border.width: tileRoot.selected ? 1 : 0
                border.color: tileRoot.selected ? Config.Palette.color("outline_variant") : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Config.Motion.shortDuration
                    }
                }
            }

            IconImage {
                source: tileRoot.iconSource
                asynchronous: true
                mipmap: true
                width: root.iconSize
                height: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: tileRoot.iconTopMargin
            }

            Text {
                text: tileRoot.appName
                color: Config.Palette.color("on_surface")
                font.family: Config.Appearance.fontFamily
                font.weight: tileRoot.selected ? Font.DemiBold : Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: tileRoot.iconTopMargin + root.iconSize + tileRoot.textTopMargin
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                onClicked: root.appActivated(tileRoot.desktopId)
            }
        }
    }
}
