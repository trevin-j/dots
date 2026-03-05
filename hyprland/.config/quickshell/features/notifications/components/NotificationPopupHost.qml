import QtQuick
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
    readonly property int slideDistance: Math.max(12, Config.Config.notifications?.popup?.slideDistance ?? 30)
    readonly property int enterOvershootPadding: Math.max(24, Math.round(root.slideDistance * 1.2))
    readonly property int offscreenDistance: root.popupWidth + root.slideDistance
    readonly property int marginTopValue: Math.max(0, (Config.Config.notifications?.popup?.marginTop ?? 48) + Config.Appearance.frameReservedBarExtent)
    readonly property int marginRightValue: Math.max(0, Config.Config.notifications?.popup?.marginRight ?? 18)

    screen: root.screen
    aboveWindows: true
    focusable: false
    exclusiveZone: 0
    color: "transparent"
    surfaceFormat.opaque: false

    anchors.top: true
    anchors.bottom: true
    anchors.right: true
    margins.right: 0

    visible: root.popupEnabled && root.active

    implicitWidth: root.popupWidth + root.marginRightValue + root.enterOvershootPadding

    mask: Region {
        item: inputMask
    }

    Item {
        id: inputMask

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.marginTopValue
        anchors.rightMargin: root.marginRightValue
        width: root.popupWidth
        height: toastList.contentHeight
    }

    ListView {
        id: toastList

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: root.marginTopValue
        anchors.rightMargin: root.marginRightValue
        width: root.popupWidth
        interactive: false
        reuseItems: false
        clip: false
        spacing: root.popupSpacing
        verticalLayoutDirection: ListView.TopToBottom
        model: root.active ? Services.NotificationService.popupModel : null

        populate: Transition {
            NumberAnimation {
                property: "x"
                from: root.offscreenDistance
                to: 0
                duration: Config.Motion.mediumDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Motion.shellCurve
            }
        }

        add: Transition {
            NumberAnimation {
                property: "x"
                from: root.offscreenDistance
                to: 0
                duration: Config.Motion.mediumDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Motion.shellCurve
            }
        }

        remove: Transition {
            NumberAnimation {
                property: "x"
                from: 0
                to: root.offscreenDistance
                duration: Config.Motion.shortDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Motion.emphasizedAccelCurve
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

        delegate: NotificationToast {
            required property var popupEntry

            entry: popupEntry
            widthValue: root.popupWidth
        }
    }
}
