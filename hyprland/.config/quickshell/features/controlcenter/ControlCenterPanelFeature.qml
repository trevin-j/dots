import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

import "../../config" as Config
import "../../design/primitives" as Primitives
import "../../services" as Services
import "./components" as ControlCenterComponents
import "../quicksettings/components" as QuickSettingsComponents
import "../quicksettings/vm" as QuickSettingsVm
import "./vm" as ControlCenterVm

/*
  ControlCenterPanelFeature
  Full-height right-edge control center drawer for quick settings and tray entries.
  Required properties: panelScreen, state.
*/
Primitives.SlideOutPanelWindow {
    id: root

    required property ControlCenterVm.ControlCenterState state

    readonly property int panelWidth: Config.Config.controlCenter?.size?.width ?? 420
    readonly property int contentPadding: Config.Config.controlCenter?.size?.padding ?? 16
    readonly property int contentSpacing: Config.Config.controlCenter?.size?.spacing ?? 12
    readonly property int traySectionSpacing: Config.Config.controlCenter?.size?.traySpacing ?? 8
    readonly property int trayItemHeight: Config.Config.controlCenter?.size?.trayItemHeight ?? 42
    readonly property int toggleHeight: Config.Config.controlCenter?.size?.toggleHeight ?? 58
    readonly property int overshootRightPadding: Config.Config.controlCenter?.size?.overshootPadding
        ?? Math.max(96, Math.round(panelWidth * 0.24))
    readonly property int drawerOpenDelay: Config.Config.controlCenter?.transition?.drawerOpenDelay ?? 0
    readonly property int wallpaperPanelWidth: Config.Config.controlCenter?.wallpaper?.panelWidth ?? 320
    readonly property int wallpaperOvershootPadding: Config.Config.controlCenter?.wallpaper?.overshootPadding ?? 64
    readonly property int panelOpenDurationMs: Config.Motion.shellDuration
    readonly property int panelCloseDurationMs: Config.Motion.shortDuration
    readonly property color surfaceColor: Config.Palette.color("surface")
    readonly property color sectionColor: Config.Palette.color("surface_container")

    open: root.state.open
    closeDurationMs: root.panelCloseDurationMs
    focusable: true

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
            root.state.wallpaperPickerOpen = false;
            trayState.trayTooltipVisible = false;
            trayState.trayTooltipSource = null;
            trayState.trayTooltipPending = null;
            tooltipTimer.stop();
        }
    }

    onOpenChanged: {
        if (root.open) {
            Services.BitwardenService.refreshVaultState();
        }
    }

    Keys.onPressed: event => {
        if (!root.state.open) {
            return;
        }

        if (event.key === Qt.Key_Escape) {
            root.state.close();
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(0, Math.round(mainPanel.visibleSurfaceX - wallpaperPanel.edgeInset))
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.state.open
        onClicked: root.state.close()
    }

    Primitives.SlideOutPanelSurface {
        id: wallpaperPanel

        z: 0
        anchors.fill: parent
        attachedEdge: "right"
        attachedInset: root.panelWidth
        primaryExtent: root.wallpaperPanelWidth
        overshootPadding: root.wallpaperOvershootPadding
        openDelay: 0
        active: root.presentationOpen
        open: root.state.wallpaperPickerOpen
        renderWhenClosed: false
        surfaceColor: root.sectionColor
        openDurationMs: root.panelOpenDurationMs
        closeDurationMs: root.panelCloseDurationMs
        openCurve: Config.Motion.shellCurve
        closeCurve: Config.Motion.emphasizedAccelCurve

        ControlCenterComponents.WallpaperSelectorPanel {
            anchors.fill: parent
            open: wallpaperPanel.open
            panelWidth: root.wallpaperPanelWidth
            visible: wallpaperPanel.edgeInset > 0
            onApplyRequested: path => Services.WallpaperService.applyWallpaper(path)
        }
    }

    Primitives.SlideOutPanelSurface {
        id: mainPanel

        z: 1
        anchors.fill: parent
        attachedEdge: "right"
        primaryExtent: root.panelWidth
        overshootPadding: root.overshootRightPadding
        openDelay: root.drawerOpenDelay
        active: root.presentationOpen
        open: root.open
        surfaceColor: root.surfaceColor

        onEdgeInsetChanged: root.state.edgeInset = edgeInset

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.contentPadding
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
                controlCenterState: root.state
                forceCollapseMenus: !root.presentationOpen
                Layout.fillWidth: true
                onPowerAction: actionId => Services.PowerService.trigger(actionId)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Config.Palette.color("outline_variant")
                opacity: 0.6
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 2

                ControlCenterComponents.NotificationsPanel {
                    anchors.fill: parent
                    panelWidth: root.panelWidth
                    open: root.presentationOpen
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Config.Palette.color("outline_variant")
                opacity: 0.6
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1

                ColumnLayout {
                    anchors.fill: parent
                    spacing: root.contentSpacing

                    Text {
                        text: "Tray"
                        font.family: Config.Appearance.fontFamily
                        font.weight: Font.DemiBold
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
            }
        }
    }

    Item {
        id: trayTooltipLayer

        z: 2
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.panelWidth
        x: mainPanel.visibleSurfaceX

        QuickSettingsComponents.TrayTooltip {
            anchors.fill: parent
            state: trayState
            maxWidth: Math.max(180, Math.round(root.panelWidth - root.contentPadding * 3))
        }
    }
}
