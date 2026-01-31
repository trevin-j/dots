import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import "../../../config" as Config
import "../../../components" as Shared
import "../../../services" as Services
import "../../../utils"

/*!
  RightStatus
  Displays wifi strength, battery, date, and time in a pill.
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
    readonly property string materialFont: "Material Symbols Rounded"

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
    readonly property int popdownRightMargin: Math.max(0, Math.round(QSWindow.window ? (QSWindow.window.width - (root.pillRect.x + root.pillRect.width)) : 0))
    readonly property int trayWidth: Math.max(240, Math.round(popdownWidth * 0.7))
    readonly property int trayPadding: popdownPadding
    readonly property int trayItemHeight: Math.max(36, Math.round(toggleHeight * 0.7))
    readonly property int trayIconSize: Math.max(18, Math.round(iconSize * 1.15))
    readonly property int traySpacing: Math.max(6, Math.round(toggleSpacing * 0.5))
    readonly property int trayMinHeight: Math.max(200, trayPadding * 2 + trayItemHeight * 3 + toggleSpacing * 2)
    readonly property int trayContentHeight: trayItemCount > 0
        ? trayItemCount * trayItemHeight + Math.max(0, (trayItemCount - 1) * traySpacing)
        : 0
    readonly property int trayTargetHeight: Math.min(popdownTargetHeight, Math.max(trayMinHeight, trayContentHeight + trayPadding * 2))
    readonly property int traySlideOffset: 0
    readonly property int trayItemCount: SystemTray.items.count

    property bool trayTooltipVisible: false
    property string trayTooltipTitle: ""
    property string trayTooltipDescription: ""
    property real trayTooltipX: 0
    property real trayTooltipY: 0
    property var trayTooltipSource: null
    property int trayTooltipDelay: 900
    property var trayTooltipPending: null
    property bool trayMenuOpen: false

    Component.onCompleted: updatePopdownTarget()

    readonly property var windowTransform: QSWindow.window?.windowTransform
    readonly property rect pillRect: {
        windowTransform;
        return QSWindow.window ? QSWindow.window.itemRect(pill) : Qt.rect(0, 0, 0, 0);
    }

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryReady: batteryDevice?.ready ?? false
    readonly property real batteryRawPercent: batteryReady ? batteryDevice.percentage : 0
    readonly property int batteryPercent: batteryReady ? Math.round(batteryRawPercent <= 1 ? batteryRawPercent * 100 : batteryRawPercent) : 0
    readonly property bool batteryLow: batteryReady && batteryPercent <= 10
    readonly property bool batteryCharging: batteryReady
        && (batteryDevice.state === UPowerDeviceState.Charging
            || batteryDevice.state === UPowerDeviceState.PendingCharge)

    readonly property string batteryIconName: {
        if (!batteryReady) {
            return "battery_unknown";
        }
        if (batteryCharging) {
            return "battery_charging_full";
        }
        if (batteryPercent >= 95) {
            return "battery_full";
        }
        if (batteryPercent >= 75) {
            return "battery_6_bar";
        }
        if (batteryPercent >= 60) {
            return "battery_5_bar";
        }
        if (batteryPercent >= 45) {
            return "battery_4_bar";
        }
        if (batteryPercent >= 30) {
            return "battery_3_bar";
        }
        if (batteryPercent >= 15) {
            return "battery_2_bar";
        }
        if (batteryPercent >= 8) {
            return "battery_1_bar";
        }
        return "battery_0_bar";
    }

    readonly property color batteryTextColor: batteryLow ? Config.Palette.color("error") : Config.Palette.color("on_surface")

    readonly property int wifiStrength: Services.ConnectivityService.wifiStrength
    readonly property bool wifiConnected: Services.ConnectivityService.wifiConnected
    readonly property bool ethernetConnected: Services.ConnectivityService.ethernetConnected

    readonly property string wifiIconName: {
        if (ethernetConnected) {
            return "settings_ethernet";
        }
        if (!wifiConnected) {
            return "wifi_off";
        }
        if (wifiStrength >= 70) {
            return "wifi";
        }
        if (wifiStrength >= 40) {
            return "wifi_2_bar";
        }
        return "wifi_1_bar";
    }

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property real volumeLevel: defaultSink?.audio?.volume ?? 0
    readonly property bool volumeMuted: defaultSink?.audio?.muted ?? false

    property bool dndEnabled: false
    property bool nightLightEnabled: false
    property bool darkModeEnabled: false

    readonly property string volumeIconName: {
        if (volumeMuted || volumeLevel <= 0) {
            return "volume_off";
        }
        if (volumeLevel < 0.3) {
            return "volume_mute";
        }
        if (volumeLevel < 0.7) {
            return "volume_down";
        }
        return "volume_up";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function formatTime(dateValue) {
        return Qt.formatDateTime(dateValue, "h:mm AP");
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight


    readonly property int popdownTop: Math.max(0, Math.round(barMarginTop + barThickness - barCornerRadius * 2 + popdownOffset))

    function updatePopdownHold() {
        if (trayMenuOpen || pillHover.hovered || popdownHover.hovered || trayHover.hovered) {
            closeHold = false;
            closeTimer.stop();
            return;
        }
        closeHold = true;
        closeTimer.restart();
    }

    property bool closeHold: false
    readonly property bool popdownOpen: trayMenuOpen || pillHover.hovered || popdownHover.hovered || trayHover.hovered || closeHold

    Rectangle {
        id: pill

        radius: Config.Appearance.radiusMedium
        color: Config.Palette.color("surface_container")

        PwObjectTracker {
            objects: [root.defaultSink]
        }

        implicitWidth: contentRow.implicitWidth + root.horizontalPadding * 2
        implicitHeight: Math.max(contentRow.implicitHeight + root.verticalPadding * 2, Math.round(root.barHeight * 0.6))

        RowLayout {
            id: contentRow

            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
            anchors.topMargin: root.verticalPadding
            anchors.bottomMargin: root.verticalPadding
            spacing: root.spacing

            Text {
                id: wifiIcon

                text: root.wifiIconName
                color: Config.Palette.color("on_surface")
                font.family: root.materialFont
                font.pixelSize: root.iconSize
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter

                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: volumeIcon

                text: root.volumeIconName
                color: Config.Palette.color("on_surface")
                font.family: root.materialFont
                font.pixelSize: root.iconSize
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter

                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: batteryIcon

                text: root.batteryIconName
                color: root.batteryTextColor
                font.family: root.materialFont
                font.pixelSize: root.iconSize
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter

                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: batteryText

                text: batteryReady ? `${batteryPercent}%` : "--%"
                color: root.batteryTextColor
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                verticalAlignment: Text.AlignVCenter

                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: dateText

                text: Qt.formatDateTime(clock.date, "ddd MMM d")
                color: Config.Palette.color("on_surface")
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                verticalAlignment: Text.AlignVCenter

                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: timeText

                text: root.formatTime(clock.date)
                color: Config.Palette.color("on_surface")
                font.family: Config.Appearance.fontFamily
                font.weight: Config.Appearance.fontWeight
                font.pixelSize: Config.Appearance.fontSizeMedium
                verticalAlignment: Text.AlignVCenter

                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    HoverHandler {
        id: pillHover
        target: pill
        onHoveredChanged: root.updatePopdownHold()
    }

    Timer {
        id: closeTimer
        interval: popdownCloseDelay
        repeat: false
        onTriggered: {
            closeHold = false;
        }
    }

    function updatePopdownTarget() {
        if (!toggleGrid) {
            return;
        }
        const target = Math.round(
            popdownPadding * 2
            + toggleGrid.implicitHeight
            + powerMenu.expandedHeight
            + toggleSpacing
        );
        popdownTargetHeight = Math.max(popdownMinHeight, target);
    }

    function showTrayTooltip(entry, titleTextValue, descriptionTextValue, mouseX, mouseY) {
        trayTooltipSource = entry;
        trayTooltipTitle = titleTextValue || "";
        trayTooltipDescription = descriptionTextValue || "";
        updateTrayTooltipPosition(entry, mouseX, mouseY);
        trayTooltipVisible = true;
    }

    function updateTrayTooltipPosition(entry, mouseX, mouseY) {
        if (!entry || !trayPopout) {
            return;
        }
        const localX = Math.max(0, Math.round(mouseX ?? entry.width * 0.5));
        const localY = Math.max(0, Math.round(mouseY ?? entry.height));
        const point = entry.mapToItem(trayTooltipLayer, localX, localY);
        trayTooltipX = Math.round(point.x);
        trayTooltipY = Math.round(point.y);
    }

    function scheduleTrayTooltip(entry, mouseX, mouseY) {
        trayTooltipPending = entry;
        trayTooltipX = mouseX ?? trayTooltipX;
        trayTooltipY = mouseY ?? trayTooltipY;
        trayTooltipTimer.restart();
    }

    function clearTrayTooltip(entry) {
        if (trayTooltipPending === entry) {
            trayTooltipPending = null;
        }
        if (trayTooltipSource === entry) {
            trayTooltipVisible = false;
            trayTooltipSource = null;
        }
        trayTooltipTimer.stop();
    }

    onPopdownOpenChanged: {
        sizeDebounce.restart();
    }

    Timer {
        id: sizeDebounce
        interval: 16
        repeat: false
        onTriggered: updatePopdownTarget()
    }

    Timer {
        id: trayTooltipTimer
        interval: root.trayTooltipDelay
        repeat: false
        onTriggered: {
            if (root.trayTooltipPending) {
                root.showTrayTooltip(
                    root.trayTooltipPending,
                    root.trayTooltipPending.trayTitleClean,
                    root.trayTooltipPending.trayDescriptionClean,
                    root.trayTooltipX,
                    root.trayTooltipY
                );
            }
        }
    }

    PanelWindow {
        id: popdown

        visible: root.popdownOpen || popdownWrapper.height > 0
        color: "transparent"
        surfaceFormat.opaque: false
        focusable: true
        exclusiveZone: 0
        screen: root.screen
        aboveWindows: true

        anchors.top: true
        anchors.right: true

        margins.top: root.popdownTop
        margins.right: root.popdownRightMargin

        implicitWidth: popdownWrapper.implicitWidth
        implicitHeight: popdownWrapper.implicitHeight

        mask: root.popdownOpen ? popdownMask : null

        Region {
            id: popdownMask
            item: popdownBody
        }

        Shared.FrameWrapper {
            id: popdownWrapper

            screen: popdown.screen
            attachEdge: "top-right"
            active: root.popdownOpen
            bubbleColorRole: "surface"
            bubblePadding: 0
            bubbleRounding: root.barCornerRadius

            width: implicitWidth
            height: root.popdownOpen ? Math.round(root.popdownTargetHeight + root.barCornerRadius) : 0
            implicitWidth: root.popdownWidth + root.barCornerRadius
            implicitHeight: root.popdownTargetHeight + root.barCornerRadius
            clip: true
            visible: root.popdownOpen || height > 0

            Behavior on height {
                Anim {
                    durationMs: Config.Motion.shellDuration
                    curve: Config.Motion.shellCurve
                }
            }

            anchors.top: parent.top

            // Height follows implicit size without re-animating content changes.

                Item {
                    id: popdownSurface

                    width: root.popdownWidth + root.barCornerRadius
                    height: root.popdownTargetHeight + root.barCornerRadius
                    anchors.top: parent.top

                    Rectangle {
                        id: popdownBody

                        width: root.popdownWidth
                        height: root.popdownTargetHeight
                        x: root.barCornerRadius
                    radius: root.barCornerRadius
                    color: root.barColor
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.left: popdownBody.left
                    anchors.top: popdownBody.top
                    color: popdownBody.color
                    z: 1
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.right: popdownBody.right
                    anchors.top: popdownBody.top
                    color: popdownBody.color
                    z: 1
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.right: popdownBody.right
                    anchors.bottom: popdownBody.bottom
                    color: popdownBody.color
                    z: 1
                }

                Shared.CornerCutout {
                    id: bottomEdgeArc

                    visible: root.barCornerRadius > 0
                    radius: root.barCornerRadius
                    fillColor: popdownBody.color
                    mirrorX: true
                    anchors.right: popdownBody.right
                    anchors.top: popdownBody.bottom
                }

                ColumnLayout {
                    id: quickSettingsLayout

                    anchors.top: parent.top
                    anchors.left: popdownBody.left
                    anchors.right: popdownBody.right
                    anchors.topMargin: root.popdownPadding
                    anchors.leftMargin: root.popdownPadding
                    anchors.rightMargin: root.popdownPadding
                    spacing: root.toggleSpacing
                    z: 2

                    GridLayout {
                        id: toggleGrid

                        columns: 2
                        columnSpacing: root.toggleSpacing
                        rowSpacing: root.toggleSpacing
                        Layout.fillWidth: true

                        Shared.QuickToggle {
                            label: "Wi-Fi"
                            icon: "wifi"
                            iconFont: root.materialFont
                            active: Services.ConnectivityService.wifiEnabled
                            secondaryText: Services.ConnectivityService.wifiConnected
                                ? Services.ConnectivityService.wifiSsid
                                : (Services.ConnectivityService.wifiEnabled ? "Not connected" : "")
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: Services.ConnectivityService.setWifiEnabled(next)
                        }

                        Shared.QuickToggle {
                            label: "Bluetooth"
                            icon: "bluetooth"
                            iconFont: root.materialFont
                            active: Services.ConnectivityService.bluetoothEnabled
                            secondaryText: Services.ConnectivityService.bluetoothDevices !== ""
                                ? Services.ConnectivityService.bluetoothDevices
                                : (Services.ConnectivityService.bluetoothEnabled ? "No devices" : "")
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: Services.ConnectivityService.setBluetoothEnabled(next)
                        }

                        Shared.QuickToggle {
                            label: "Airplane"
                            icon: "airplanemode_active"
                            iconFont: root.materialFont
                            active: Services.ConnectivityService.airplaneEnabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: Services.ConnectivityService.setAirplaneEnabled(next)
                        }

                        Shared.QuickToggle {
                            label: "Do Not Disturb"
                            icon: "notifications_off"
                            iconFont: root.materialFont
                            active: root.dndEnabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: root.dndEnabled = next
                        }

                        Shared.QuickToggle {
                            label: "Night Light"
                            icon: "nightlight"
                            iconFont: root.materialFont
                            active: root.nightLightEnabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: root.nightLightEnabled = next
                        }

                        Shared.QuickToggle {
                            label: "Dark Mode"
                            icon: "dark_mode"
                            iconFont: root.materialFont
                            active: root.darkModeEnabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.toggleHeight
                            onToggled: root.darkModeEnabled = next
                        }

                    }

                    Shared.PowerMenu {
                        id: powerMenu

                        iconFont: root.materialFont
                        spacing: root.toggleSpacing
                        itemHeight: Math.max(36, Math.round(root.toggleHeight * 0.8))
                        Layout.fillWidth: true
                        onActionTriggered: {
                            if (actionId === "lock") {
                                Services.PowerService.lock();
                                return;
                            }
                            if (actionId === "suspend") {
                                Services.PowerService.suspend();
                                return;
                            }
                            if (actionId === "hibernate") {
                                Services.PowerService.hibernate();
                                return;
                            }
                            if (actionId === "logout") {
                                Services.PowerService.logout();
                                return;
                            }
                            if (actionId === "reboot") {
                                Services.PowerService.reboot();
                                return;
                            }
                            if (actionId === "poweroff") {
                                Services.PowerService.poweroff();
                            }
                        }
                    }
                }
            }

            HoverHandler {
                id: popdownHover
                target: popdownWrapper
                onHoveredChanged: root.updatePopdownHold()
            }
        }
    }

    PanelWindow {
        id: trayPopout

        visible: root.popdownOpen || trayWrapper.height > 0
        color: "transparent"
        surfaceFormat.opaque: false
        focusable: true
        exclusiveZone: 0
        screen: root.screen
        aboveWindows: true

        anchors.top: true
        anchors.right: true

        margins.top: root.popdownTop
        margins.right: root.popdownRightMargin + root.popdownWidth

        implicitWidth: trayWrapper.implicitWidth
        implicitHeight: trayWrapper.implicitHeight

        mask: (root.popdownOpen && !root.trayTooltipVisible) ? trayMask : null

        Region {
            id: trayMask
            item: trayBody
        }

        Shared.FrameWrapper {
            id: trayWrapper

            screen: trayPopout.screen
            attachEdge: "top-right"
            active: root.popdownOpen
            bubbleColorRole: "surface"
            bubblePadding: 0
            bubbleRounding: root.barCornerRadius

            width: implicitWidth
            height: root.popdownOpen ? Math.round(root.trayTargetHeight + root.barCornerRadius) : 0
            implicitWidth: root.trayWidth + root.barCornerRadius
            implicitHeight: root.trayTargetHeight + root.barCornerRadius
            clip: true
            visible: root.popdownOpen || height > 0
            x: root.popdownOpen ? 0 : root.traySlideOffset
            opacity: root.popdownOpen ? 1 : 0

            Behavior on height {
                Anim {
                    durationMs: Config.Motion.shellDuration
                    curve: Config.Motion.shellCurve
                }
            }

            Behavior on x {
                Anim {
                    durationMs: Config.Motion.shellDuration
                    curve: Config.Motion.shellCurve
                }
            }

            Behavior on opacity {
                Anim {
                    durationMs: Config.Motion.shellDuration
                    curve: Config.Motion.shellCurve
                }
            }

            anchors.top: parent.top

            Item {
                id: traySurface

                width: root.trayWidth + root.barCornerRadius
                height: root.trayTargetHeight + root.barCornerRadius
                anchors.top: parent.top

                Rectangle {
                    id: trayBody

                    width: root.trayWidth
                    height: root.trayTargetHeight
                    x: root.barCornerRadius
                    radius: root.barCornerRadius
                    color: root.barColor
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.left: trayBody.left
                    anchors.top: trayBody.top
                    color: trayBody.color
                    z: 1
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.right: trayBody.right
                    anchors.top: trayBody.top
                    color: trayBody.color
                    z: 1
                }

                Rectangle {
                    width: root.barCornerRadius
                    height: root.barCornerRadius
                    anchors.right: trayBody.right
                    anchors.bottom: trayBody.bottom
                    color: trayBody.color
                    z: 1
                }

                Shared.CornerCutout {
                    visible: root.barCornerRadius > 0
                    radius: root.barCornerRadius
                    fillColor: trayBody.color
                    mirrorX: true
                    anchors.right: trayBody.left
                    anchors.top: trayBody.top
                }

                Shared.CornerCutout {
                    visible: root.barCornerRadius > 0
                    radius: root.barCornerRadius
                    fillColor: trayBody.color
                    mirrorX: true
                    anchors.right: trayBody.right
                    anchors.top: trayBody.bottom
                }

                ColumnLayout {
                    id: trayLayout

                    anchors.top: parent.top
                    anchors.left: trayBody.left
                    anchors.right: trayBody.right
                    anchors.bottom: trayBody.bottom
                    anchors.topMargin: root.trayPadding
                    anchors.leftMargin: root.trayPadding
                    anchors.rightMargin: root.trayPadding
                    anchors.bottomMargin: root.trayPadding
                    spacing: Math.max(8, Math.round(root.toggleSpacing * 0.6))
                    z: 2

                    Loader {
                        id: trayContentLoader

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        active: root.popdownOpen
                        sourceComponent: trayContentComponent
                    }

                    Component {
                        id: trayContentComponent

                        Item {
                            anchors.fill: parent

                            ListView {
                                id: trayView

                                anchors.fill: parent
                                visible: count > 0
                                clip: false
                                spacing: root.traySpacing
                                boundsBehavior: Flickable.StopAtBounds
                                reuseItems: true
                                cacheBuffer: root.trayItemHeight * 6
                                model: SystemTray.items

                                delegate: Item {
                                    id: trayEntry

                                    readonly property var trayItem: modelData
                                    readonly property string trayTitle: trayItem.tooltipTitle || trayItem.title || trayItem.id
                                    readonly property string trayDescription: trayItem.tooltipDescription || ""
                                    readonly property string trayTitleClean: trayTitle ? trayTitle.replace(/[\r\n]+/g, " ") : ""
                                    readonly property string trayDescriptionClean: trayDescription ? trayDescription.replace(/[\r\n]+/g, " ") : ""
                                    readonly property bool titleElided: titleText.contentWidth > titleText.width
                                    readonly property bool descriptionElided: descriptionText.visible && descriptionText.contentWidth > descriptionText.width
                                    property bool hovered: trayEntryArea.containsMouse
                                    property real lastMouseX: width * 0.5
                                    property real lastMouseY: height

                                    function openTrayMenuAt(mouseX, mouseY) {
                                        if (!trayItem || !trayItem.hasMenu) {
                                            return;
                                        }
                                        trayMenu.anchor.item = trayEntry;
                                        trayMenu.anchor.rect = Qt.rect(
                                            Math.round(mouseX ?? trayEntry.width * 0.5),
                                            Math.round(mouseY ?? trayEntry.height),
                                            1,
                                            1
                                        );
                                        trayMenu.open();
                                    }

                                    function handleClick(mouseEvent) {
                                        if (!mouseEvent) {
                                            return;
                                        }
                                        if (mouseEvent.button === Qt.LeftButton) {
                                            if (trayItem.onlyMenu) {
                                                trayEntry.openTrayMenuAt(mouseEvent.x, mouseEvent.y);
                                            } else {
                                                trayItem.activate();
                                            }
                                        } else if (mouseEvent.button === Qt.MiddleButton) {
                                            trayItem.secondaryActivate();
                                        } else if (mouseEvent.button === Qt.RightButton) {
                                            trayEntry.openTrayMenuAt(mouseEvent.x, mouseEvent.y);
                                        }
                                    }

                                    width: trayView.width
                                    height: root.trayItemHeight

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Config.Appearance.radiusSmall
                                        color: trayEntry.hovered ? Config.Palette.color("surface_container_high") : "transparent"
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        IconImage {
                                            source: trayItem.icon
                                            implicitSize: root.trayIconSize
                                            asynchronous: true
                                            mipmap: true
                                            Layout.preferredWidth: root.trayIconSize
                                            Layout.preferredHeight: root.trayIconSize
                                        }

                                        ColumnLayout {
                                            spacing: 2
                                            Layout.fillWidth: true

                                            Text {
                                                id: titleText

                                                text: trayTitleClean
                                                font.family: Config.Appearance.fontFamily
                                                font.weight: Config.Appearance.fontWeight
                                                font.pixelSize: Config.Appearance.fontSizeMedium
                                                color: Config.Palette.color("on_surface")
                                                elide: Text.ElideRight
                                                wrapMode: Text.NoWrap
                                                maximumLineCount: 1
                                                textFormat: Text.PlainText
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                id: descriptionText

                                                visible: trayDescriptionClean !== ""
                                                text: trayDescriptionClean
                                                font.family: Config.Appearance.fontFamily
                                                font.weight: Config.Appearance.fontWeight
                                                font.pixelSize: Math.max(10, Math.round(Config.Appearance.fontSizeSmall))
                                                color: Config.Palette.color("on_surface_variant")
                                                elide: Text.ElideRight
                                                wrapMode: Text.NoWrap
                                                maximumLineCount: 1
                                                textFormat: Text.PlainText
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: trayEntryArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                        onEntered: root.scheduleTrayTooltip(trayEntry, trayEntry.lastMouseX, trayEntry.lastMouseY)
                                        onExited: {
                                            root.clearTrayTooltip(trayEntry);
                                        }
                                        onPositionChanged: {
                                            trayEntry.lastMouseX = mouse.x;
                                            trayEntry.lastMouseY = mouse.y;
                                            if (root.trayTooltipSource === trayEntry) {
                                                root.updateTrayTooltipPosition(trayEntry, mouse.x, mouse.y);
                                            } else if (root.trayTooltipPending === trayEntry) {
                                                root.trayTooltipX = mouse.x;
                                                root.trayTooltipY = mouse.y;
                                            }
                                        }
                                        onClicked: function(mouse) {
                                            trayEntry.handleClick(mouse);
                                        }
                                    }

                                    QsMenuAnchor {
                                        id: trayMenu
                                        menu: trayItem && trayItem.hasMenu ? trayItem.menu : null

                                        onOpened: {
                                            root.trayMenuOpen = true;
                                            root.updatePopdownHold();
                                        }

                                        onClosed: {
                                            root.trayMenuOpen = false;
                                            root.updatePopdownHold();
                                        }
                                    }

                                    onYChanged: {
                                        if (root.trayTooltipSource === trayEntry && trayEntryArea.containsMouse) {
                                            root.updateTrayTooltipPosition(trayEntry);
                                        }
                                    }

                                    WheelHandler {
                                        target: trayEntry
                                        onWheel: event => {
                                            if (!trayItem) {
                                                return;
                                            }
                                            const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
                                            const delta = horizontal ? event.angleDelta.x : event.angleDelta.y;
                                            trayItem.scroll(Math.round(delta), horizontal);
                                            event.accepted = true;
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: trayView.count === 0
                                text: "No tray items"
                                font.family: Config.Appearance.fontFamily
                                font.weight: Config.Appearance.fontWeight
                                font.pixelSize: Config.Appearance.fontSizeMedium
                                color: Config.Palette.color("on_surface_variant")
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                height: root.trayItemHeight
                                width: parent.width
                            }
                        }
                    }
                }
            }

            HoverHandler {
                id: trayHover
                target: trayWrapper
                onHoveredChanged: root.updatePopdownHold()
            }
        }

        Item {
            id: trayTooltipLayer

            anchors.fill: parent
            z: 30
            visible: root.trayTooltipVisible

            Item {
                id: trayTooltipBubble

                readonly property int padding: 8
                readonly property int maxWidth: Math.max(160, Math.round(root.trayWidth - root.trayPadding * 2))
                width: maxWidth
                height: Math.max(24, Math.round(tooltipContent.implicitHeight + padding * 2))
                x: Math.min(Math.max(0, root.trayTooltipX), Math.max(0, trayTooltipLayer.width - width))
                y: Math.min(
                    Math.max(0, Math.round(root.trayTooltipY - height - 6)),
                    Math.max(0, trayTooltipLayer.height - height)
                )

                Rectangle {
                    anchors.fill: parent
                    radius: Config.Appearance.radiusSmall
                    color: Config.Palette.color("surface_container_high")
                }

                Column {
                    id: tooltipContent

                    anchors.fill: parent
                    anchors.margins: trayTooltipBubble.padding
                    spacing: 4
                    width: trayTooltipBubble.width - trayTooltipBubble.padding * 2

                    Text {
                        text: root.trayTooltipTitle
                        font.family: Config.Appearance.fontFamily
                        font.weight: Config.Appearance.fontWeight
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        color: Config.Palette.color("on_surface")
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        width: tooltipContent.width
                        visible: text !== ""
                    }

                    Text {
                        visible: root.trayTooltipDescription !== ""
                        text: root.trayTooltipDescription
                        font.family: Config.Appearance.fontFamily
                        font.weight: Config.Appearance.fontWeight
                        font.pixelSize: Math.max(10, Math.round(Config.Appearance.fontSizeSmall))
                        color: Config.Palette.color("on_surface_variant")
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        width: tooltipContent.width
                    }
                }
            }
        }
    }

}
