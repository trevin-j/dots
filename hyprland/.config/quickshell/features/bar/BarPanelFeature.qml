import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../config" as Config
import "../../design/primitives" as Primitives
import "../../services" as Services
import "./components" as BarComponents

/*
  BarPanelFeature
  Main bar panel composition for a single screen.
*/
PanelWindow {
    id: root

    required property ShellScreen panelScreen
    required property var controlCenterState

    readonly property string position: Config.Config.bar.position || "top"
    readonly property int thickness: Config.Config.bar.size?.thickness ?? 40
    readonly property int padding: Config.Config.bar.size?.padding ?? 10
    readonly property int margin: Config.Config.bar.size?.margin ?? 10
    readonly property int marginTop: Config.Config.bar.size?.marginTop ?? margin
    readonly property int marginBottom: Config.Config.bar.size?.marginBottom ?? margin
    readonly property int marginSide: Config.Config.bar.size?.marginSide ?? margin
    readonly property int spacing: Config.Config.bar.size?.spacing ?? 8
    readonly property int edgeMargin: position === "top"
        ? marginTop
        : position === "bottom"
            ? marginBottom
            : marginSide
    readonly property bool exclusive: Config.Config.bar.behavior?.exclusiveZone ?? true
    screen: root.panelScreen
    aboveWindows: true

    color: "transparent"
    surfaceFormat.opaque: false
    focusable: false

    anchors.top: position === "top"
    anchors.bottom: position === "bottom"
    anchors.left: position === "left" || position === "top" || position === "bottom"
    anchors.right: position === "right" || position === "top" || position === "bottom"

    margins.top: position === "top" ? marginTop : 0
    margins.bottom: position === "bottom" ? marginBottom : 0
    margins.left: position === "left" ? marginSide : 0
    margins.right: position === "right" ? marginSide : 0
    exclusiveZone: exclusive ? thickness + edgeMargin : 0

    readonly property real visualThickness: (position === "top" || position === "bottom")
        ? thickness + cornerRadius
        : thickness

    implicitWidth: (position === "left" || position === "right") ? thickness : 0
    implicitHeight: (position === "top" || position === "bottom") ? visualThickness : 0

    readonly property real cornerRadius: Math.min(Config.Appearance.radiusLarge, thickness * 0.5)
    readonly property color barColor: Config.Palette.color("surface")

    function openPickerMenu(buttonItem, mouseX, mouseY) {
        if (pickerMenu.open) {
            pickerMenu.closeMenu();
            return;
        }

        const point = buttonItem.mapToItem(contentLayer, mouseX, mouseY);
        const desiredLeft = Math.max(root.padding, Math.min(root.width - pickerMenu.popupWidth - root.padding, Math.round(point.x - 12)));
        pickerMenu.rightMargin = Math.max(root.padding, Math.round(root.width - desiredLeft - pickerMenu.popupWidth));
        pickerMenu.topMargin = Math.max(0, Math.round(root.marginTop + root.thickness - 2));
        pickerMenu.open = true;
    }

    function dispatchPickerAction(actionId) {
        if (actionId === "password") {
            Services.BitwardenService.toggleMode("password");
            return;
        }
        if (actionId === "username") {
            Services.BitwardenService.toggleMode("username");
            return;
        }
        if (actionId === "totp") {
            Services.BitwardenService.toggleMode("totp");
            return;
        }
        if (actionId === "clipboard") {
            Services.ClipboardHistoryService.toggle();
            return;
        }
        if (actionId === "emoji") {
            Services.SymbolPickerService.toggleKind("emoji");
            return;
        }
        if (actionId === "nerdfont") {
            Services.SymbolPickerService.toggleKind("nerdfont");
        }
    }

    Item {
        id: shadowShape

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.visualThickness
        visible: false

        Rectangle {
            id: shadowBarBase

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.thickness
            color: root.barColor
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: root.barColor
            anchors.left: parent.left
            anchors.top: shadowBarBase.bottom
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: root.barColor
            mirrorX: true
            anchors.right: parent.right
            anchors.top: shadowBarBase.bottom
        }
    }

    Primitives.SurfaceShadow {
        source: shadowShape
        enabled: Config.Appearance.shadowEnabled
    }

    Item {
        id: contentLayer

        anchors.fill: parent

        Rectangle {
            id: barBase

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.thickness
            color: root.barColor
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            anchors.left: parent.left
            anchors.top: parent.top
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: Config.Appearance.cutoutBlack
            mirrorX: true
            anchors.right: parent.right
            anchors.top: parent.top
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: root.barColor
            anchors.left: parent.left
            anchors.top: barBase.bottom
        }

        Primitives.CornerCutout {
            visible: root.position === "top" && root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: root.barColor
            mirrorX: true
            anchors.right: parent.right
            anchors.top: barBase.bottom
        }

        Item {
            anchors.left: barBase.left
            anchors.right: barBase.right
            anchors.top: barBase.top
            anchors.leftMargin: root.padding
            anchors.rightMargin: root.padding
            anchors.topMargin: root.padding
            height: barBase.height - root.padding * 2

            RowLayout {
                anchors.fill: parent
                spacing: root.spacing

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 0
                    Layout.fillHeight: true
                    spacing: root.spacing

                    BarComponents.PickerMenuButton {
                        visible: Config.Config.bar.searchMenu?.enabled ?? true
                        barHeight: root.thickness - root.padding * 2
                        iconFont: Config.Appearance.iconFontFamily
                        active: pickerMenu.open
                        Layout.fillHeight: true
                        Layout.preferredWidth: visible ? implicitWidth : 0
                        onClicked: mouse => root.openPickerMenu(this, mouse.x, mouse.y)
                    }

                    BarComponents.AppDrawerButton {
                        barHeight: root.thickness - root.padding * 2
                        iconFont: Config.Appearance.iconFontFamily
                        active: Services.AppDrawerService.isTargetOpen()
                        Layout.fillHeight: true
                        onClicked: Services.AppDrawerService.toggle()
                    }

                    BarComponents.Workspaces {
                        screen: root.panelScreen
                        vertical: root.position === "left" || root.position === "right"
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillHeight: true
                    spacing: root.spacing

                    BarComponents.ActiveWindowPill {
                        screen: root.panelScreen
                        barHeight: root.thickness - root.padding * 2
                        Layout.fillHeight: true
                    }

                    BarComponents.RightStatus {
                        barHeight: root.thickness - root.padding * 2
                        spacing: root.spacing
                        Layout.fillHeight: true
                    }

                    BarComponents.KeyboardToggle {
                        barHeight: root.thickness - root.padding * 2
                        iconFont: Config.Appearance.iconFontFamily
                        Layout.fillHeight: true
                        onClicked: Services.KeyboardService.toggle()
                    }

                    BarComponents.ControlCenterButton {
                        barHeight: root.thickness - root.padding * 2
                        iconFont: Config.Appearance.iconFontFamily
                        active: root.controlCenterState?.open ?? false
                        hasPendingNotifications: Services.NotificationService.hasNotifications
                        Layout.fillHeight: true
                        onClicked: Services.ControlCenterService.toggle()
                    }
                }
            }
        }

    }

    BarComponents.PickerContextMenu {
        id: pickerMenu

        screen: root.panelScreen
        onActionRequested: actionId => root.dispatchPickerAction(actionId)
    }
}
