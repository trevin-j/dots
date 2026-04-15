import QtQuick

import "../../../config" as Config
import "../../../design/primitives" as Primitives

/*
  AppDrawerContextMenu
  Shell-styled context menu overlay for app drawer item actions.
*/
Item {
    id: root

    property bool open: false
    property real menuX: 0
    property real menuY: 0
    property string desktopId: ""
    property bool pinned: false
    property bool hidden: false
    property bool showHidden: false

    readonly property int contentPadding: 8
    readonly property int rowHeight: 36
    readonly property int menuWidth: 208
    readonly property int iconSize: Math.max(16, Math.round(Config.Appearance.fontSizeMedium + 3))
    readonly property real popupWidth: card.width
    readonly property real popupHeight: card.height

    signal pinRequested(bool nextPinned)
    signal hideRequested(bool nextHidden)
    signal showHiddenRequested(bool nextShowHidden)
    signal dismissed()

    function closeMenu() {
        if (!root.open) {
            return;
        }

        root.open = false;
        root.dismissed();
    }

    visible: root.open
    z: 30

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: mouse => {
            mouse.accepted = true;
            root.closeMenu();
        }
    }

    Primitives.SurfaceShadow {
        source: card
        offsetX: 0
        offsetY: 8
    }

    Rectangle {
        id: card

        x: root.menuX
        y: root.menuY
        width: root.menuWidth
        height: contentColumn.implicitHeight + root.contentPadding * 2
        radius: Config.Appearance.radiusMedium
        color: Config.Palette.color("surface_container")
        border.width: 1
        border.color: Config.Palette.color("outline_variant")

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => {
                mouse.accepted = true;
            }
        }

        Column {
            id: contentColumn

            anchors.fill: parent
            anchors.margins: root.contentPadding
            spacing: 4

            Rectangle {
                width: parent.width
                height: root.rowHeight
                radius: Config.Appearance.radiusSmall
                color: pinArea.containsMouse ? Config.Palette.color("surface_container_high") : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        width: root.iconSize
                        height: parent.height
                        text: "push_pin"
                        color: Config.Palette.color("on_surface_variant")
                        font.family: Config.Appearance.iconFontFamily
                        font.pixelSize: root.iconSize
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width - root.iconSize - 10
                        height: parent.height
                        text: root.pinned ? "Unpin" : "Pin"
                        color: Config.Palette.color("on_surface")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        font.weight: Font.Medium
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: pinArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.pinRequested(!root.pinned);
                        root.closeMenu();
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: root.rowHeight
                radius: Config.Appearance.radiusSmall
                color: hideArea.containsMouse ? Config.Palette.color("surface_container_high") : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        width: root.iconSize
                        height: parent.height
                        text: root.hidden ? "visibility" : "visibility_off"
                        color: Config.Palette.color("on_surface_variant")
                        font.family: Config.Appearance.iconFontFamily
                        font.pixelSize: root.iconSize
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width - root.iconSize - 10
                        height: parent.height
                        text: root.hidden ? "Unhide" : "Hide"
                        color: Config.Palette.color("on_surface")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        font.weight: Font.Medium
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: hideArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.hideRequested(!root.hidden);
                        root.closeMenu();
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Config.Palette.color("outline_variant")
                opacity: 0.7
            }

            Rectangle {
                width: parent.width
                height: root.rowHeight
                radius: Config.Appearance.radiusSmall
                color: showHiddenArea.containsMouse ? Config.Palette.color("surface_container_high") : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        width: root.iconSize
                        height: parent.height
                        text: root.showHidden ? "check" : "visibility_off"
                        color: Config.Palette.color("on_surface_variant")
                        font.family: Config.Appearance.iconFontFamily
                        font.pixelSize: root.iconSize
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width - root.iconSize - 10
                        height: parent.height
                        text: "Show Hidden"
                        color: Config.Palette.color("on_surface")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        font.weight: Font.Medium
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: showHiddenArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.showHiddenRequested(!root.showHidden);
                        root.closeMenu();
                    }
                }
            }
        }
    }
}
