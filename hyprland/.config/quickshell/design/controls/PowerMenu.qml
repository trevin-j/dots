import QtQuick
import QtQuick.Layouts

import "../../config" as Config
import "../../utils"

/*
  PowerMenu
  Power action list with confirmation.
*/
Item {
    id: root

    required property string iconFont

    property int itemHeight: Math.max(36, Math.round(Config.Appearance.fontSizeMedium * 2.4))
    property int spacing: 8
    signal actionTriggered(string actionId)

    property int pendingIndex: -1
    property int pressedIndex: -1
    property int hoveredIndex: -1

    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "lock", danger: false },
        { id: "suspend", label: "Suspend", icon: "mode_night", danger: false },
        { id: "hibernate", label: "Hibernate", icon: "snooze", danger: false },
        { id: "logout", label: "Log out", icon: "logout", danger: true },
        { id: "reboot", label: "Reboot", icon: "restart_alt", danger: true },
        { id: "poweroff", label: "Power off", icon: "power_settings_new", danger: true }
    ]
    readonly property int itemCount: actions.length
    readonly property int expandedHeight: itemCount * itemHeight + Math.max(0, (itemCount - 1) * spacing)

    implicitHeight: expandedHeight
    implicitWidth: content.implicitWidth

    function indexFromY(positionY) {
        const step = root.itemHeight + root.spacing;
        if (step <= 0) {
            return -1;
        }
        const index = Math.floor(positionY / step);
        if (index < 0 || index >= root.itemCount) {
            return -1;
        }
        const localOffset = positionY - index * step;
        if (localOffset > root.itemHeight) {
            return -1;
        }
        return index;
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: root.spacing

        Repeater {
            model: root.actions

            delegate: Rectangle {
                readonly property int actionIndex: index
                readonly property bool isPending: root.pendingIndex === actionIndex
                readonly property bool isConfirm: isPending && root.hoveredIndex === actionIndex
                readonly property bool pressed: root.pressedIndex === actionIndex

                width: content.width
                height: root.itemHeight
                implicitWidth: width
                implicitHeight: height
                Layout.fillWidth: true
                Layout.preferredHeight: root.itemHeight
                radius: isConfirm ? Config.Appearance.radiusMedium : Config.Appearance.radiusSmall
                color: "transparent"
                scale: pressed ? 0.97 : 1

                Behavior on radius {
                    Anim {
                        durationMs: Config.Motion.shortDuration
                        curve: Config.Motion.standardCurve
                    }
                }

                Behavior on scale {
                    Anim {
                        durationMs: Config.Motion.shortDuration
                        curve: Config.Motion.standardCurve
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Config.Palette.color("primary")
                    opacity: isConfirm ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            durationMs: Config.Motion.shortDuration
                            curve: Config.Motion.standardCurve
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: modelData.icon
                        font.family: root.iconFont
                        font.pixelSize: Math.round(parent.height * 0.5)
                        font.weight: Font.Medium
                        color: isConfirm
                            ? Config.Palette.color("on_primary")
                            : Config.Palette.color("on_surface")
                        verticalAlignment: Text.AlignVCenter
                        Layout.preferredWidth: implicitWidth
                    }

                    Text {
                        text: isConfirm ? "Confirm" : modelData.label
                        font.family: Config.Appearance.fontFamily
                        font.weight: Config.Appearance.fontWeight
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        color: isConfirm
                            ? Config.Palette.color("on_primary")
                            : Config.Palette.color("on_surface")
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPressed: {
            const index = root.indexFromY(mouse.y);
            root.pressedIndex = index;
            root.hoveredIndex = index;
        }
        onPositionChanged: {
            const index = root.indexFromY(mouse.y);
            root.hoveredIndex = index;
            if (pressed) {
                root.pressedIndex = index;
            }
            if (root.pendingIndex !== -1 && root.pendingIndex !== index) {
                root.pendingIndex = -1;
            }
        }
        onCanceled: {
            root.pressedIndex = -1;
            root.pendingIndex = -1;
        }
        onReleased: root.pressedIndex = -1
        onExited: {
            root.hoveredIndex = -1;
            root.pendingIndex = -1;
        }
        onClicked: {
            const index = root.indexFromY(mouse.y);
            if (index >= 0) {
                if (root.pendingIndex === index) {
                    root.pendingIndex = -1;
                    root.actionTriggered(root.actions[index].id);
                } else {
                    root.pendingIndex = index;
                }
            }
        }
    }
}
