import QtQuick
import Quickshell

import "../../../config" as Config
import "../../../design/primitives" as Primitives

/*
  PickerContextMenu
  Lightweight bar popover for mouse-first picker launching with y-only motion.
 */
Item {
    id: root

    required property ShellScreen screen
    property bool open: false
    property int topMargin: 0
    property int rightMargin: 0
    property bool rendered: false

    readonly property int contentPadding: 8
    readonly property int rowHeight: 36
    readonly property int menuWidth: 224
    readonly property int iconSize: Math.max(16, Math.round(Config.Appearance.fontSizeMedium + 3))
    readonly property int menuHeight: contentColumn.implicitHeight + root.contentPadding * 2
    readonly property int popupWidth: root.menuWidth
    readonly property int popupHeight: root.menuHeight
    readonly property var primaryActions: [
        { label: "Passwords", icon: "password", actionId: "password" },
        { label: "Usernames", icon: "person", actionId: "username" },
        { label: "TOTP codes", icon: "pin", actionId: "totp" }
    ]
    readonly property var secondaryActions: [
        { label: "Clipboard history", icon: "content_paste", actionId: "clipboard" },
        { label: "Emoji", icon: "emoji_emotions", actionId: "emoji" },
        { label: "Nerd Font", icon: "font_download", actionId: "nerdfont" }
    ]

    signal actionRequested(string actionId)
    signal dismissed()

    function closeMenu() {
        if (!root.open && !root.rendered) {
            return;
        }

        root.open = false;
        root.dismissed();
    }

    onOpenChanged: {
        if (root.open) {
            root.rendered = true;
            closeAnimation.stop();
            openAnimation.restart();
        } else if (root.rendered) {
            openAnimation.stop();
            closeAnimation.restart();
        }
    }

    PanelWindow {
        id: menuWindow

        screen: root.screen
        visible: root.rendered
        aboveWindows: true
        focusable: false
        exclusiveZone: 0
        color: "transparent"
        surfaceFormat.opaque: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: mouse => {
                mouse.accepted = true;
                root.closeMenu();
            }
        }

        Primitives.SurfaceShadow {
            source: card
            enabled: Config.Appearance.shadowEnabled && root.rendered
            offsetX: 0
            offsetY: 8
        }

        Rectangle {
            id: card

            width: root.menuWidth
            height: root.menuHeight
            x: Math.max(0, parent.width - root.rightMargin - width)
            y: -root.menuHeight
            radius: Config.Appearance.radiusMedium
            color: Config.Palette.color("surface_container")
            border.width: 1
            border.color: Config.Palette.color("outline_variant")

            Column {
                id: contentColumn

                anchors.fill: parent
                anchors.margins: root.contentPadding
                spacing: 4

                Repeater {
                    model: root.primaryActions

                    delegate: Rectangle {
                        width: parent.width
                        height: root.rowHeight
                        radius: Config.Appearance.radiusSmall
                        color: rowArea.containsMouse ? Config.Palette.color("surface_container_high") : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                width: root.iconSize
                                height: parent.height
                                text: modelData.icon
                                color: Config.Palette.color("on_surface_variant")
                                font.family: Config.Appearance.iconFontFamily
                                font.pixelSize: root.iconSize
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: parent.width - root.iconSize - 10
                                height: parent.height
                                text: modelData.label
                                color: Config.Palette.color("on_surface")
                                font.family: Config.Appearance.fontFamily
                                font.pixelSize: Config.Appearance.fontSizeMedium
                                font.weight: Font.Medium
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: rowArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.actionRequested(modelData.actionId);
                                root.closeMenu();
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Config.Palette.color("outline_variant")
                    opacity: 0.7
                }

                Repeater {
                    model: root.secondaryActions

                    delegate: Rectangle {
                        width: parent.width
                        height: root.rowHeight
                        radius: Config.Appearance.radiusSmall
                        color: rowArea.containsMouse ? Config.Palette.color("surface_container_high") : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                width: root.iconSize
                                height: parent.height
                                text: modelData.icon
                                color: Config.Palette.color("on_surface_variant")
                                font.family: Config.Appearance.iconFontFamily
                                font.pixelSize: root.iconSize
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: parent.width - root.iconSize - 10
                                height: parent.height
                                text: modelData.label
                                color: Config.Palette.color("on_surface")
                                font.family: Config.Appearance.fontFamily
                                font.pixelSize: Config.Appearance.fontSizeMedium
                                font.weight: Font.Medium
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: rowArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.actionRequested(modelData.actionId);
                                root.closeMenu();
                            }
                        }
                    }
                }
            }
        }

        NumberAnimation {
            id: openAnimation
            target: card
            property: "y"
            from: -root.menuHeight
            to: root.topMargin
            duration: Config.Motion.shortDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Motion.standardCurve
        }

        NumberAnimation {
            id: closeAnimation
            target: card
            property: "y"
            from: card.y
            to: -root.menuHeight
            duration: Config.Motion.shortDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Motion.standardCurve
            onStopped: {
                if (!root.open) {
                    root.rendered = false;
                }
            }
        }
    }
}
