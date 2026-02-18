import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../../../config" as Config
import "../../quicksettings/vm" as QuickSettingsVm
import "../../quicksettings/components" as QuickSettingsComponents

/*
  RightStatus
  Composes status pill, quick settings popover, and tray popover.
  Required properties: barHeight, spacing, screen.
*/
Item {
    id: root

    required property int barHeight
    required property int spacing
    required property ShellScreen screen

    readonly property int horizontalPadding: Math.max(6, Math.round(spacing * 0.75))
    readonly property int verticalPadding: Math.max(4, Math.round(horizontalPadding * 0.6))
    readonly property int iconSize: Math.max(14, Math.round(barHeight * 0.45))
    readonly property string materialFont: Config.Appearance.iconFontFamily

    readonly property int popdownWidth: Math.max(320, Math.round(barHeight * 10.5))
    readonly property int popdownPadding: Math.max(12, Math.round(spacing * 1.6))
    readonly property int popdownOffset: 0
    readonly property int popdownCloseDelay: 140
    readonly property int barThickness: Config.Config.bar.size?.thickness ?? barHeight
    readonly property real barCornerRadius: Math.min(Config.Appearance.radiusLarge, barThickness * 0.5)
    readonly property color barColor: Config.Palette.color("surface")
    readonly property int toggleHeight: Math.max(52, Math.round(barHeight * 1.6))
    readonly property int toggleSpacing: Math.max(12, Math.round(spacing * 1.5))
    readonly property int popdownMinHeight: Math.max(260, popdownPadding * 2 + toggleHeight * 4 + toggleSpacing * 3)
    property int popdownTargetHeight: popdownMinHeight
    readonly property int barMargin: Config.Config.bar.size?.margin ?? 10
    readonly property int barMarginTop: Config.Config.bar.size?.marginTop ?? barMargin
    readonly property int trayWidth: Math.max(240, Math.round(popdownWidth * 0.7))
    readonly property int trayPadding: popdownPadding
    readonly property int trayItemHeight: Math.max(36, Math.round(toggleHeight * 0.7))
    readonly property int trayIconSize: Math.max(18, Math.round(iconSize * 1.15))
    readonly property int traySpacing: Math.max(6, Math.round(toggleSpacing * 0.5))
    readonly property int trayMinHeight: Math.max(200, trayPadding * 2 + trayItemHeight * 3 + toggleSpacing * 2)
    readonly property int trayItemCount: SystemTray.items.count
    readonly property int trayContentHeight: trayItemCount > 0
        ? trayItemCount * trayItemHeight + Math.max(0, (trayItemCount - 1) * traySpacing)
        : 0
    readonly property int trayTargetHeight: Math.min(popdownTargetHeight, Math.max(trayMinHeight, trayContentHeight + trayPadding * 2))
    readonly property int traySlideOffset: 0

    readonly property int popdownTop: Math.max(0, Math.round(barMarginTop + barThickness - barCornerRadius * 2 + popdownOffset))

    readonly property var windowTransform: QSWindow.window?.windowTransform
    readonly property rect pillRect: {
        windowTransform;
        return QSWindow.window ? QSWindow.window.itemRect(pill) : Qt.rect(0, 0, 0, 0);
    }
    readonly property int popdownRightMargin: Math.max(0, Math.round(QSWindow.window ? (QSWindow.window.width - (root.pillRect.x + root.pillRect.width)) : 0))

    readonly property bool popdownOpen: popoverState.popdownOpen

    QuickSettingsVm.StatusViewModel {
        id: statusVm
    }

    QuickSettingsVm.PopoverState {
        id: popoverState
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    function updatePopdownTarget() {
        const target = Math.round(popdownPadding * 2 + quickSettingsPopover.contentPreferredHeight);
        popdownTargetHeight = Math.max(popdownMinHeight, target);
    }

    function updatePopdownHold() {
        popoverState.pillHovered = pillHover.hovered;
        popoverState.quickSettingsHovered = quickSettingsPopover.hovered;
        popoverState.trayHovered = trayPopover.hovered;

        if (popoverState.trayMenuOpen || popoverState.pillHovered || popoverState.quickSettingsHovered || popoverState.trayHovered) {
            popoverState.closeHold = false;
            closeTimer.stop();
            return;
        }

        popoverState.closeHold = true;
        closeTimer.restart();
    }

    onPopdownOpenChanged: sizeDebounce.restart()

    Connections {
        target: popoverState

        function onTrayMenuOpenChanged() {
            root.updatePopdownHold();
        }
    }

    QuickSettingsComponents.StatusPill {
        id: pill

        barHeight: root.barHeight
        spacing: root.spacing
        materialFont: root.materialFont
        iconSize: root.iconSize
        horizontalPadding: root.horizontalPadding
        verticalPadding: root.verticalPadding
        viewModel: statusVm
    }

    HoverHandler {
        id: pillHover
        target: pill
        onHoveredChanged: root.updatePopdownHold()
    }

    Timer {
        id: closeTimer
        interval: root.popdownCloseDelay
        repeat: false
        onTriggered: popoverState.closeHold = false
    }

    Timer {
        id: sizeDebounce
        interval: 16
        repeat: false
        onTriggered: root.updatePopdownTarget()
    }

    Component.onCompleted: {
        root.updatePopdownTarget();
        root.updatePopdownHold();
    }

    QuickSettingsComponents.QuickSettingsPopover {
        id: quickSettingsPopover

        screen: root.screen
        open: root.popdownOpen
        topMargin: root.popdownTop
        rightMargin: root.popdownRightMargin
        widthValue: root.popdownWidth
        targetHeight: root.popdownTargetHeight
        cornerRadius: root.barCornerRadius
        surfaceColor: root.barColor
        contentPadding: root.popdownPadding
        toggleHeight: root.toggleHeight
        toggleSpacing: root.toggleSpacing
        materialFont: root.materialFont
        state: statusVm

        onHoveredChanged: root.updatePopdownHold()
    }

    QuickSettingsComponents.TrayPopover {
        id: trayPopover

        screen: root.screen
        open: root.popdownOpen
        topMargin: root.popdownTop
        rightMargin: root.popdownRightMargin + root.popdownWidth
        widthValue: root.trayWidth
        targetHeight: root.trayTargetHeight
        cornerRadius: root.barCornerRadius
        surfaceColor: root.barColor
        contentPadding: root.trayPadding
        itemHeight: root.trayItemHeight
        iconSize: root.trayIconSize
        itemSpacing: root.traySpacing
        slideOffset: root.traySlideOffset
        state: popoverState

        onHoveredChanged: root.updatePopdownHold()
    }
}
