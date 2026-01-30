import QtQuick
import QtQuick.Layouts

import "../config" as Config
import "../utils"

/*!
  PowerMenu
  Power action list with confirmation.
  Required properties: iconFont.
*/
Item {
    id: root

    required property string iconFont

    property int itemHeight: Math.max(36, Math.round(Config.Appearance.fontSizeMedium * 2.4))
    property int spacing: 8
    property int confirmTimeoutMs: 1800

    signal actionTriggered(string actionId)

    property string pendingAction: ""

    readonly property int itemCount: 6
    readonly property int expandedHeight: itemCount * itemHeight + Math.max(0, (itemCount - 1) * spacing)

    implicitHeight: expandedHeight
    implicitWidth: content.implicitWidth

    function requestAction(actionId) {
        if (root.pendingAction === actionId) {
            root.pendingAction = "";
            confirmTimer.stop();
            root.actionTriggered(actionId);
            return;
        }
        root.pendingAction = actionId;
        confirmTimer.restart();
    }

    Timer {
        id: confirmTimer
        interval: root.confirmTimeoutMs
        repeat: false
        onTriggered: root.pendingAction = ""
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: root.spacing

        Repeater {
            model: [
                { id: "lock", label: "Lock", icon: "lock", danger: false },
                { id: "suspend", label: "Suspend", icon: "mode_night", danger: false },
                { id: "hibernate", label: "Hibernate", icon: "snooze", danger: false },
                { id: "logout", label: "Log out", icon: "logout", danger: true },
                { id: "reboot", label: "Reboot", icon: "restart_alt", danger: true },
                { id: "poweroff", label: "Power off", icon: "power_settings_new", danger: true }
            ]

            delegate: Rectangle {
                readonly property bool isPending: root.pendingAction === modelData.id

                width: content.width
                height: root.itemHeight
                radius: Config.Appearance.radiusSmall
                color: isPending
                    ? (modelData.danger ? Config.Palette.color("error_container") : Config.Palette.color("surface_container_high"))
                    : Config.Palette.color("surface_container")

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
                        color: isPending
                            ? (modelData.danger ? Config.Palette.color("on_error_container") : Config.Palette.color("on_surface"))
                            : Config.Palette.color("on_surface")
                        verticalAlignment: Text.AlignVCenter
                        Layout.preferredWidth: implicitWidth
                    }

                    Text {
                        text: isPending ? "Confirm" : modelData.label
                        font.family: Config.Appearance.fontFamily
                        font.weight: Config.Appearance.fontWeight
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        color: isPending
                            ? (modelData.danger ? Config.Palette.color("on_error_container") : Config.Palette.color("on_surface"))
                            : Config.Palette.color("on_surface")
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.requestAction(modelData.id)
                }
            }
        }
    }
}
