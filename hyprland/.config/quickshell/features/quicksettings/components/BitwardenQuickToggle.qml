import QtQuick

import "../../../config" as Config
import "../../../services" as Services
import "../../../utils"

/*
  BitwardenQuickToggle
  Tri-state quick settings control for Bitwarden vault state.
 */
Item {
    id: root

    required property int controlHeight
    required property string iconFont
    required property bool controlCenterOpen

    property bool logoutConfirmArmed: false

    readonly property bool busy: Services.BitwardenService.vaultBusy
    readonly property bool unlocked: Services.BitwardenService.vaultUnlocked
    readonly property bool loggedOut: !Services.BitwardenService.vaultConfigured
    readonly property bool enabledState: !root.busy && !root.loggedOut
    readonly property bool active: root.unlocked
    readonly property color activeColor: Config.Palette.color("primary")
    readonly property color inactiveColor: Config.Palette.color("surface_container")
    readonly property color disabledColor: Config.Palette.color("surface_container")
    readonly property color activeTextColor: Config.Palette.color("on_primary")
    readonly property color inactiveTextColor: Config.Palette.color("on_surface")
    readonly property color inactiveIconColor: Config.Palette.color("on_surface_variant")
    readonly property string secondaryText: root.busy
        ? Services.BitwardenService.vaultBusyText()
        : (root.loggedOut
            ? "Open a picker to configure and sign in"
            : (root.unlocked
                ? "Click to lock Bitwarden"
                : (root.logoutConfirmArmed
                    ? "Click again to log out"
                    : "Click to arm log out")))

    implicitWidth: Math.max(140, rowContent.implicitWidth + Math.max(12, Math.round(background.height * 0.3)) * 2)
    implicitHeight: Math.max(root.controlHeight, Math.round(Config.Appearance.fontSizeMedium * 3.6))

    onControlCenterOpenChanged: {
        if (!root.controlCenterOpen) {
            root.logoutConfirmArmed = false;
        }
    }

    onUnlockedChanged: {
        if (root.unlocked) {
            root.logoutConfirmArmed = false;
        }
    }

    onLoggedOutChanged: {
        if (root.loggedOut) {
            root.logoutConfirmArmed = false;
        }
    }

    Rectangle {
        id: background

        anchors.fill: parent
        radius: root.active ? Config.Appearance.radiusMedium : height / 2
        color: root.active
            ? root.activeColor
            : (root.loggedOut ? root.disabledColor : root.inactiveColor)
        opacity: root.enabledState ? 1 : 0.55
        scale: toggleArea.pressed ? 0.96 : 1

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

        Row {
            id: rowContent

            anchors.fill: parent
            anchors.leftMargin: Math.max(12, Math.round(background.height * 0.3))
            anchors.rightMargin: Math.max(12, Math.round(background.height * 0.3))
            spacing: Math.max(8, Math.round(background.height * 0.22))

            Text {
                width: implicitWidth
                height: parent.height
                text: root.busy ? "sync_lock" : (root.unlocked ? "lock_open_right" : "lock")
                font.family: root.iconFont
                font.pixelSize: Math.round(background.height * 0.5)
                font.weight: Font.Medium
                color: root.active ? root.activeTextColor : root.inactiveIconColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x
                spacing: 2

                Text {
                    width: parent.width
                    text: "Bitwarden"
                    font.family: Config.Appearance.fontFamily
                    font.weight: Config.Appearance.fontWeight
                    font.pixelSize: Config.Appearance.fontSizeMedium
                    color: root.active ? root.activeTextColor : root.inactiveTextColor
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.secondaryText
                    font.family: Config.Appearance.fontFamily
                    font.weight: Config.Appearance.fontWeight
                    font.pixelSize: Math.max(10, Math.round(Config.Appearance.fontSizeSmall))
                    color: root.active ? root.activeTextColor : root.inactiveIconColor
                    elide: Text.ElideRight
                }
            }
        }
    }

    MouseArea {
        id: toggleArea

        anchors.fill: parent
        hoverEnabled: false
        enabled: !root.busy && !root.loggedOut
        onClicked: {
            if (root.unlocked) {
                root.logoutConfirmArmed = false;
                Services.BitwardenService.lockVault();
                return;
            }

            if (root.logoutConfirmArmed) {
                root.logoutConfirmArmed = false;
                Services.BitwardenService.logoutVault();
                return;
            }

            root.logoutConfirmArmed = true;
        }
    }
}
