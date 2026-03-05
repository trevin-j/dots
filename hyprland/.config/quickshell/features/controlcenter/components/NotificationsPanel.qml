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
    readonly property var activeModel: Services.NotificationService.activeModel
    readonly property int contentPadding: Math.max(8, Config.Config.notifications?.popup?.itemPadding ?? 12)
    readonly property int iconSize: Math.max(16, Config.Config.notifications?.popup?.iconSize ?? 22)

    property real currentTimeMs: Date.now()

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

        const deltaSeconds = Math.max(0, Math.floor((root.currentTimeMs - receivedAtMs) / 1000));
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

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.currentTimeMs = Date.now()
    }

    implicitHeight: sectionColumn.implicitHeight

    ColumnLayout {
        id: sectionColumn

        anchors.fill: parent
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
                visible: root.allowClearAll
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
            Layout.fillHeight: true
            implicitHeight: listColumn.implicitHeight + 10
            radius: Config.Appearance.radiusMedium
            color: Config.Palette.color("surface_container")

            ColumnLayout {
                id: listColumn

                anchors.fill: parent
                anchors.margins: 10
                spacing: root.rowSpacing

                ListView {
                    id: notificationsList

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    interactive: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: root.rowSpacing
                    model: root.activeModel

                    footer: Item {
                        width: notificationsList.width
                        height: root.rowSpacing
                    }

                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Config.Motion.shortDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Motion.standardCurve
                        }
                    }

                    remove: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Config.Motion.shortDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Motion.standardCurve
                        }
                    }

                    addDisplaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Config.Motion.mediumDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Motion.standardCurve
                        }
                    }

                    removeDisplaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Config.Motion.mediumDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Motion.standardCurve
                        }
                    }

                    move: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Config.Motion.mediumDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Motion.standardCurve
                        }
                    }

                    moveDisplaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Config.Motion.mediumDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Motion.standardCurve
                        }
                    }

                    delegate: Rectangle {
                        id: delegateRoot

                        required property var notificationEntry

                        readonly property var modelData: notificationEntry

                        readonly property bool critical: String(modelData.urgency || "").toLowerCase().indexOf("critical") >= 0
                        readonly property bool hasBody: (modelData.body || "") !== ""
                        readonly property color surfaceColor: critical
                            ? Config.Palette.color("error_container")
                            : Config.Palette.color("surface_container_high")
                        readonly property color metaColor: critical
                            ? Config.Palette.color("on_error_container")
                            : Config.Palette.color("on_surface_variant")

                        Layout.fillWidth: true
                        width: notificationsList.width
                        height: implicitHeight
                        implicitHeight: contentColumn.implicitHeight + root.contentPadding * 2
                        radius: Config.Appearance.radiusMedium
                        color: surfaceColor

                        ColumnLayout {
                            id: contentColumn

                            anchors.fill: parent
                            anchors.margins: root.contentPadding
                            spacing: Math.max(6, Math.round(root.contentPadding * 0.6))

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Math.max(8, Math.round(root.contentPadding * 0.6))

                                IconImage {
                                    source: root.iconSource(modelData.notification?.appIcon)
                                    asynchronous: true
                                    mipmap: true
                                    implicitSize: root.iconSize
                                    Layout.preferredWidth: root.iconSize
                                    Layout.preferredHeight: root.iconSize
                                    Layout.alignment: Qt.AlignTop
                                }

                                RowLayout {
                                    spacing: 2
                                    Layout.fillWidth: true

                                    ColumnLayout {
                                        spacing: 2
                                        Layout.fillWidth: true

                                        Text {
                                            text: modelData.appName || "Notification"
                                            font.family: Config.Appearance.fontFamily
                                            font.weight: Font.DemiBold
                                            font.pixelSize: Config.Appearance.fontSizeSmall
                                            color: metaColor
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            textFormat: Text.PlainText
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.summary || "Notification"
                                            font.family: Config.Appearance.fontFamily
                                            font.weight: Font.DemiBold
                                            font.pixelSize: Config.Appearance.fontSizeMedium
                                            color: critical ? Config.Palette.color("on_error_container") : Config.Palette.color("on_surface_variant")
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                            textFormat: Text.PlainText
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        visible: root.showTimestamps
                                        text: root.ageLabel(modelData.receivedAtMs)
                                        font.family: Config.Appearance.fontFamily
                                        font.weight: Config.Appearance.fontWeight
                                        font.pixelSize: Config.Appearance.fontSizeSmall
                                        color: metaColor
                                    }

                                    Text {
                                        text: "close"
                                        font.family: Config.Appearance.iconFontFamily
                                        font.pixelSize: Config.Appearance.fontSizeLarge
                                        color: metaColor

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: Services.NotificationService.dismiss(modelData)
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: hasBody
                                text: modelData.body
                                font.family: Config.Appearance.fontFamily
                                font.weight: Config.Appearance.fontWeight
                                font.pixelSize: Config.Appearance.fontSizeMedium
                                color: metaColor
                                wrapMode: Text.Wrap
                                maximumLineCount: 5
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                visible: (modelData.notification?.actions?.length ?? 0) > 0
                                Layout.fillWidth: true
                                spacing: Math.max(6, Math.round(root.contentPadding * 0.5))

                                Repeater {
                                    model: modelData.notification?.actions ?? []

                                    delegate: Rectangle {
                                        required property var modelData

                                        radius: Config.Appearance.radiusSmall
                                        color: Config.Palette.color("surface")
                                        implicitHeight: Math.max(28, Math.round(Config.Appearance.fontSizeMedium * 2.1))
                                        implicitWidth: actionText.implicitWidth + 14

                                        Text {
                                            id: actionText
                                            anchors.centerIn: parent
                                            text: modelData.text || "Action"
                                            font.family: Config.Appearance.fontFamily
                                            font.weight: Font.Medium
                                            font.pixelSize: Config.Appearance.fontSizeSmall
                                            color: Config.Palette.color("on_surface")
                                            textFormat: Text.PlainText
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: Services.NotificationService.invokeAction(delegateRoot.modelData, modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            }

            Text {
                anchors.centerIn: parent
                text: "No notifications"
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                color: Config.Palette.color("on_surface_variant")
                opacity: Services.NotificationService.hasNotifications ? 0 : 1
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.Motion.shortDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Config.Motion.standardCurve
                    }
                }
            }
        }
    }
}
