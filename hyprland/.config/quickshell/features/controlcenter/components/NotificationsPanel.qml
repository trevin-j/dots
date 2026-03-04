import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import "../../../config" as Config
import "../../../services" as Services

/*
  NotificationsPanel
  Notification history section for control center.
  Required properties: panelWidth, open.
*/
Item {
    id: root

    required property int panelWidth
    required property bool open

    readonly property int maxVisible: Math.max(1, Config.Config.notifications?.panel?.maxVisible ?? 8)
    readonly property int rowSpacing: Math.max(4, Config.Config.notifications?.panel?.itemSpacing ?? 8)
    readonly property int rowMinHeight: Math.max(66, Config.Config.notifications?.panel?.itemMinHeight ?? 84)
    readonly property bool showTimestamps: Config.Config.notifications?.panel?.showTimestamps ?? true
    readonly property bool allowClearAll: Config.Config.notifications?.panel?.allowClearAll ?? true
    readonly property int unreadCount: Services.NotificationService.unreadCount
    readonly property var visibleEntries: Services.NotificationService.history.slice(0, root.maxVisible)

    function iconSource(iconName) {
        const raw = typeof iconName === "string" ? iconName.trim() : "";
        if (!raw) {
            return Quickshell.iconPath("notifications", true);
        }
        if (raw.startsWith("/") || raw.startsWith("file:/")) {
            return raw;
        }
        return Quickshell.iconPath(raw, true);
    }

    function ageLabel(receivedAtMs) {
        if (!receivedAtMs || !showTimestamps) {
            return "";
        }

        const deltaSeconds = Math.max(0, Math.floor((Date.now() - receivedAtMs) / 1000));
        if (deltaSeconds < 60) {
            return `${deltaSeconds}s`;
        }
        if (deltaSeconds < 3600) {
            return `${Math.floor(deltaSeconds / 60)}m`;
        }
        if (deltaSeconds < 86400) {
            return `${Math.floor(deltaSeconds / 3600)}h`;
        }
        return `${Math.floor(deltaSeconds / 86400)}d`;
    }

    onOpenChanged: {
        if (root.open) {
            Services.NotificationService.markAllRead();
        }
    }

    implicitHeight: sectionColumn.implicitHeight

    ColumnLayout {
        id: sectionColumn

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Math.max(8, root.rowSpacing)

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: unreadCount > 0 ? `Notifications (${unreadCount})` : "Notifications"
                font.family: Config.Appearance.fontFamily
                font.weight: Font.DemiBold
                font.pixelSize: Config.Appearance.fontSizeMedium
                color: Config.Palette.color("on_surface")
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.allowClearAll && Services.NotificationService.hasNotifications
                color: Config.Palette.color("surface_container_high")
                radius: Config.Appearance.radiusSmall
                implicitHeight: 28
                implicitWidth: clearText.implicitWidth + 14

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear all"
                    font.family: Config.Appearance.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: Config.Appearance.fontSizeSmall
                    color: Config.Palette.color("on_surface")
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Services.NotificationService.dismissAll()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: listColumn.implicitHeight + 10
            radius: Config.Appearance.radiusMedium
            color: Config.Palette.color("surface_container")

            ColumnLayout {
                id: listColumn

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                spacing: root.rowSpacing

                Text {
                    visible: !Services.NotificationService.hasNotifications
                    text: "No notifications"
                    font.family: Config.Appearance.fontFamily
                    font.weight: Config.Appearance.fontWeight
                    font.pixelSize: Config.Appearance.fontSizeMedium
                    color: Config.Palette.color("on_surface_variant")
                    Layout.fillWidth: true
                }

                Repeater {
                    model: root.visibleEntries

                    delegate: Rectangle {
                        required property var modelData

                        readonly property bool critical: String(modelData.urgency || "").toLowerCase().indexOf("critical") >= 0

                        Layout.fillWidth: true
                        implicitHeight: Math.max(root.rowMinHeight, contentRow.implicitHeight + 16)
                        radius: Config.Appearance.radiusSmall
                        color: critical ? Config.Palette.color("error_container") : Config.Palette.color("surface")

                        RowLayout {
                            id: contentRow

                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            IconImage {
                                source: root.iconSource(modelData.notification?.appIcon)
                                asynchronous: true
                                mipmap: true
                                implicitSize: 20
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignTop
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.summary || "Notification"
                                        font.family: Config.Appearance.fontFamily
                                        font.weight: Font.DemiBold
                                        font.pixelSize: Config.Appearance.fontSizeMedium
                                        color: critical ? Config.Palette.color("on_error_container") : Config.Palette.color("on_surface")
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: root.showTimestamps
                                        text: root.ageLabel(modelData.receivedAtMs)
                                        font.family: Config.Appearance.fontFamily
                                        font.weight: Config.Appearance.fontWeight
                                        font.pixelSize: Config.Appearance.fontSizeSmall
                                        color: critical ? Config.Palette.color("on_error_container") : Config.Palette.color("on_surface_variant")
                                    }
                                }

                                Text {
                                    visible: modelData.body !== ""
                                    text: modelData.body
                                    font.family: Config.Appearance.fontFamily
                                    font.weight: Config.Appearance.fontWeight
                                    font.pixelSize: Config.Appearance.fontSizeSmall
                                    color: critical ? Config.Palette.color("on_error_container") : Config.Palette.color("on_surface_variant")
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                text: "close"
                                font.family: Config.Appearance.iconFontFamily
                                font.pixelSize: Config.Appearance.fontSizeLarge
                                color: critical ? Config.Palette.color("on_error_container") : Config.Palette.color("on_surface_variant")

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Services.NotificationService.dismiss(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
