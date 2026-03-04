import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../../config" as Config
import "../../../services" as Services

/*
  NotificationPopupHost
  Anchored popup stack host for notification toasts.
  Required properties: screen, active.
*/
PanelWindow {
    id: root

    required property ShellScreen screen
    required property bool active

    readonly property bool popupEnabled: Config.Config.notifications?.popup?.enabled ?? true
    readonly property int popupWidth: Math.max(260, Config.Config.notifications?.popup?.width ?? 360)
    readonly property int popupSpacing: Math.max(4, Config.Config.notifications?.popup?.spacing ?? 10)
    readonly property int marginTopValue: Math.max(0, (Config.Config.notifications?.popup?.marginTop ?? 48) + Config.Appearance.frameReservedBarExtent)
    readonly property int marginRightValue: Math.max(0, Config.Config.notifications?.popup?.marginRight ?? 18)

    screen: root.screen
    aboveWindows: true
    focusable: false
    exclusiveZone: 0
    color: "transparent"
    surfaceFormat.opaque: false

    anchors.top: true
    anchors.right: true
    margins.top: root.marginTopValue
    margins.right: root.marginRightValue

    visible: root.popupEnabled && root.active && Services.NotificationService.hasPopups

    implicitWidth: root.popupWidth
    implicitHeight: toastColumn.implicitHeight

    ColumnLayout {
        id: toastColumn

        width: root.popupWidth
        spacing: root.popupSpacing

        Repeater {
            model: Services.NotificationService.popupNotifications

            delegate: NotificationToast {
                required property var modelData

                Layout.fillWidth: true
                entry: modelData
                widthValue: root.popupWidth
            }
        }
    }
}
