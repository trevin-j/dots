import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

import "../../config" as Config
import "../../design/primitives" as Primitives
import "../../services" as Services
import "../../utils"
import "./components" as ControlCenterComponents
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
    readonly property int drawerOpenDelay: Config.Config.controlCenter?.transition?.drawerOpenDelay ?? 0
    readonly property int wallpaperPanelWidth: Config.Config.controlCenter?.wallpaper?.panelWidth ?? 320
    readonly property int wallpaperOvershootPadding: Config.Config.controlCenter?.wallpaper?.overshootPadding ?? 64
    readonly property color surfaceColor: Config.Palette.color("surface")
    readonly property color sectionColor: Config.Palette.color("surface_container")

    property bool drawerOpen: false
    property real wallpaperReveal: (root.state.open && root.state.wallpaperPickerOpen) ? root.wallpaperPanelWidth : 0
    property real drawerOffset: drawerOpen ? 0 : (root.panelWidth + root.overshootRightPadding)
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

    visible: root.state.open || root.drawerOpen || drawerOffset < (root.panelWidth + root.overshootRightPadding)

    onDrawerOffsetChanged: root.state.edgeInset = Math.round(revealWidth)

    onVisibleChanged: {
        if (!visible) {
            root.drawerOpen = false;
            root.state.wallpaperPickerOpen = false;
            openDelayTimer.stop();
            trayState.trayTooltipVisible = false;
            trayState.trayTooltipSource = null;
            trayState.trayTooltipPending = null;
            tooltipTimer.stop();
        }
    }

    Component.onCompleted: {
        if (root.state.open) {
            if (root.drawerOpenDelay <= 0) {
                root.drawerOpen = true;
            } else {
                openDelayTimer.restart();
            }
        }
    }

    Connections {
        target: root.state

        function onOpenChanged() {
            if (root.state.open) {
                if (root.drawerOpenDelay <= 0) {
                    root.drawerOpen = true;
                } else {
                    openDelayTimer.restart();
                }
            } else {
                openDelayTimer.stop();
                root.drawerOpen = false;
            }
        }
    }

    Timer {
        id: openDelayTimer

        interval: root.drawerOpenDelay
        repeat: false
        onTriggered: {
            if (root.state.open) {
                root.drawerOpen = true;
            }
        }
    }

    Behavior on drawerOffset {
        Anim {
            durationMs: Config.Motion.shellDuration
            curve: Config.Motion.shellCurve
        }
    }

    Behavior on wallpaperReveal {
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

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(0, Math.round(root.drawerX - root.wallpaperReveal))
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: root.state.close()
    }

    Item {
        id: drawerShadowShape

        readonly property real shadowRadius: Config.Appearance.frameBorderRounding

        width: root.panelWidth + root.wallpaperReveal + shadowRadius
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: root.drawerX - root.wallpaperReveal - shadowRadius
        visible: true
        opacity: 0

        Rectangle {
            id: shadowBody

            width: root.panelWidth + root.wallpaperReveal
            height: parent.height
            x: drawerShadowShape.shadowRadius
            color: root.surfaceColor
        }

        Primitives.CornerCutout {
            visible: drawerShadowShape.shadowRadius > 0
            radius: drawerShadowShape.shadowRadius
            fillColor: root.surfaceColor
            mirrorX: true
            anchors.right: shadowBody.left
            anchors.top: shadowBody.top
        }

        Primitives.CornerCutout {
            visible: drawerShadowShape.shadowRadius > 0
            radius: drawerShadowShape.shadowRadius
            fillColor: root.surfaceColor
            mirrorX: true
            mirrorY: true
            anchors.right: shadowBody.left
            anchors.bottom: shadowBody.bottom
        }
    }

    Primitives.SurfaceShadow {
        source: drawerShadowShape
        enabled: root.revealWidth > 0 && Config.Appearance.shadowEnabled
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
                controlCenterState: root.state
                forceCollapseMenus: !root.state.open
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
                    open: root.state.open
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
                        text: (SystemTray.items.values?.length ?? 0) > 0 ? "Tray" : "Tray (empty)"
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
            }
        }

        Item {
            id: wallpaperPanelContainer

            z: -1
            width: root.wallpaperPanelWidth + root.wallpaperOvershootPadding
            anchors.top: body.top
            anchors.bottom: body.bottom
            x: -root.wallpaperReveal
            clip: false

            Rectangle {
                id: wallpaperBody

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width
                radius: 0
                color: root.sectionColor
            }

            ControlCenterComponents.WallpaperSelectorPanel {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.wallpaperPanelWidth
                open: root.state.open && root.state.wallpaperPickerOpen
                panelWidth: root.wallpaperPanelWidth
                visible: root.wallpaperReveal > 0
                onApplyRequested: path => Services.WallpaperService.applyWallpaper(path)
            }

            Primitives.CornerCutout {
                visible: root.wallpaperReveal > 0
                radius: Config.Appearance.frameBorderRounding
                fillColor: wallpaperBody.color
                mirrorX: true
                anchors.right: wallpaperBody.left
                anchors.top: wallpaperBody.top
            }

            Primitives.CornerCutout {
                visible: root.wallpaperReveal > 0
                radius: Config.Appearance.frameBorderRounding
                fillColor: wallpaperBody.color
                mirrorX: true
                mirrorY: true
                anchors.right: wallpaperBody.left
                anchors.bottom: wallpaperBody.bottom
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

    Keys.onPressed: event => {
        if (!root.state.open) {
            return;
        }
        if (event.key === Qt.Key_Escape) {
            root.state.close();
            event.accepted = true;
        }
    }
}
