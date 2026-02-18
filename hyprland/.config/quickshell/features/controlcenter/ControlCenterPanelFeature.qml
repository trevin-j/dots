import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

import "../../config" as Config
import "../../design/primitives" as Primitives
import "../../services" as Services
import "../../utils"
import "../quicksettings/components" as QuickSettingsComponents
import "../quicksettings/vm" as QuickSettingsVm
import "./vm" as ControlCenterVm

/*
  ControlCenterPanelFeature
  Full-height right-edge control center drawer for quick settings and tray entries.
  Required properties: panelScreen, state.
*/
PanelWindow {
    id: root

    required property ShellScreen panelScreen
    required property ControlCenterVm.ControlCenterState state

    readonly property int panelWidth: Config.Config.controlCenter?.size?.width ?? 420
    readonly property int contentPadding: Config.Config.controlCenter?.size?.padding ?? 16
    readonly property int contentSpacing: Config.Config.controlCenter?.size?.spacing ?? 12
    readonly property int traySectionSpacing: Config.Config.controlCenter?.size?.traySpacing ?? 8
    readonly property int trayItemHeight: Config.Config.controlCenter?.size?.trayItemHeight ?? 42
    readonly property int toggleHeight: Config.Config.controlCenter?.size?.toggleHeight ?? 58
    readonly property int overshootRightPadding: Config.Config.controlCenter?.size?.overshootPadding
        ?? Math.max(96, Math.round(panelWidth * 0.24))
    readonly property color surfaceColor: Config.Palette.color("surface")
    readonly property color sectionColor: Config.Palette.color("surface_container")

    property real drawerOffset: root.state.open ? 0 : (root.panelWidth + root.overshootRightPadding)
    readonly property real revealWidth: Math.max(0, root.panelWidth - Math.max(0, drawerOffset))
    readonly property real drawerX: width - root.panelWidth + drawerOffset

    screen: root.panelScreen
    aboveWindows: true
    focusable: true
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    visible: root.state.open || drawerOffset < (root.panelWidth + root.overshootRightPadding)

    onDrawerOffsetChanged: root.state.edgeInset = Math.round(revealWidth)

    Behavior on drawerOffset {
        Anim {
            durationMs: Config.Motion.shellDuration
            curve: Config.Motion.shellCurve
        }
    }

    QuickSettingsVm.StatusViewModel {
        id: statusVm
    }

    QuickSettingsVm.PopoverState {
        id: trayState
    }

    Timer {
        id: tooltipTimer
        interval: trayState.trayTooltipDelay
        repeat: false
        onTriggered: {
            if (trayState.trayTooltipPending) {
                trayState.showTrayTooltip(
                    trayState.trayTooltipPending,
                    trayState.trayTooltipPending.trayTitleClean,
                    trayState.trayTooltipPending.trayDescriptionClean,
                    trayTooltipLayer,
                    trayState.trayTooltipX,
                    trayState.trayTooltipY
                );
            }
        }
    }

    onVisibleChanged: {
        if (!visible) {
            trayState.trayTooltipVisible = false;
            trayState.trayTooltipSource = null;
            trayState.trayTooltipPending = null;
            tooltipTimer.stop();
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(0, Math.round(root.drawerX))
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: root.state.close()
    }

    Item {
        id: drawer

        width: root.panelWidth + root.overshootRightPadding
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: root.drawerX
        clip: false

        Rectangle {
            id: body

            anchors.fill: parent
            radius: 0
            color: root.surfaceColor
        }

        ColumnLayout {
            anchors.left: body.left
            anchors.top: body.top
            anchors.bottom: body.bottom
            anchors.leftMargin: root.contentPadding
            anchors.topMargin: root.contentPadding
            anchors.bottomMargin: root.contentPadding
            width: Math.max(0, root.panelWidth - root.contentPadding * 2)
            spacing: root.contentSpacing

            Text {
                text: "Control Center"
                font.family: Config.Appearance.fontFamily
                font.weight: Font.DemiBold
                font.pixelSize: Math.max(16, Math.round(Config.Appearance.fontSizeLarge * 1.1))
                color: Config.Palette.color("on_surface")
                Layout.fillWidth: true
            }

            QuickSettingsComponents.QuickSettingsGrid {
                toggleHeight: root.toggleHeight
                toggleSpacing: root.contentSpacing
                materialFont: Config.Appearance.iconFontFamily
                state: statusVm
                Layout.fillWidth: true
                onPowerAction: actionId => Services.PowerService.trigger(actionId)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Config.Palette.color("outline_variant")
                opacity: 0.6
            }

            Text {
                text: SystemTray.items.count > 0 ? "Tray" : "Tray (empty)"
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                color: Config.Palette.color("on_surface_variant")
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Config.Appearance.radiusMedium
                color: root.sectionColor
                clip: true

                QuickSettingsComponents.TrayList {
                    anchors.fill: parent
                    anchors.margins: root.contentPadding
                    itemHeight: root.trayItemHeight
                    iconSize: Math.max(18, Math.round(root.toggleHeight * 0.38))
                    spacing: root.traySectionSpacing
                    tooltipLayer: trayTooltipLayer
                    tooltipTimer: tooltipTimer
                    state: trayState
                }
            }
        }

        Primitives.CornerCutout {
            visible: root.revealWidth > 0
            radius: Config.Appearance.frameBorderRounding
            fillColor: body.color
            mirrorX: true
            anchors.right: body.left
            anchors.top: body.top
        }

        Primitives.CornerCutout {
            visible: root.revealWidth > 0
            radius: Config.Appearance.frameBorderRounding
            fillColor: body.color
            mirrorX: true
            mirrorY: true
            anchors.right: body.left
            anchors.bottom: body.bottom
        }

        Item {
            id: trayTooltipLayer
            anchors.left: body.left
            anchors.top: body.top
            anchors.bottom: body.bottom
            width: root.panelWidth

            QuickSettingsComponents.TrayTooltip {
                anchors.fill: parent
                state: trayState
                maxWidth: Math.max(180, Math.round(root.panelWidth - root.contentPadding * 3))
            }
        }
    }

    Primitives.CornerCutout {
        visible: root.revealWidth > 0
        radius: Config.Appearance.frameBorderRounding
        fillColor: Config.Appearance.cutoutBlack
        mirrorX: true
        mirrorY: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }
}
