import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import "../../../config" as Config
import "../../../components" as Shared
import "../../../utils"

/*!
  RightStatus
  Displays wifi strength, battery, date, and time in a pill.
  Required properties: barHeight, spacing.
*/
Item {
    id: root

    required property int barHeight
    required property int spacing

    readonly property int horizontalPadding: Math.max(6, Math.round(spacing * 0.75))
    readonly property int verticalPadding: Math.max(4, Math.round(horizontalPadding * 0.6))
    readonly property int iconSize: Math.max(14, Math.round(barHeight * 0.45))
    readonly property string materialFont: "Material Symbols Rounded"

    readonly property int popdownWidth: Math.max(200, Math.round(barHeight * 6.5))
    readonly property int popdownHeight: Math.max(120, Math.round(barHeight * 4.5))
    readonly property int popdownPadding: Math.max(8, Math.round(spacing * 1.1))
    readonly property int popdownOffset: 0
    readonly property int popdownCloseDelay: 140
    readonly property int barThickness: Config.Config.bar.size?.thickness ?? barHeight
    readonly property real barCornerRadius: Math.min(Config.Appearance.radiusLarge, barThickness * 0.5)
    readonly property color barColor: Config.Palette.color("surface")

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

    property int wifiStrength: -1
    property bool wifiConnected: false
    property bool ethernetConnected: false

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


    function updatePopdownHold() {
        if (pillHover.containsMouse || popdownHover.containsMouse) {
            closeHold = false;
            closeTimer.stop();
            return;
        }
        closeHold = true;
        closeTimer.restart();
    }

    property bool closeHold: false
    readonly property bool popdownOpen: pillHover.containsMouse || popdownHover.containsMouse || closeHold

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

    MouseArea {
        id: pillHover
        anchors.fill: pill
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: root.updatePopdownHold()
    }

    Timer {
        id: closeTimer
        interval: popdownCloseDelay
        repeat: false
        onTriggered: closeHold = false
    }

    PanelWindow {
        id: popdown

        visible: root.popdownOpen || popdownWrapper.implicitHeight > 0
        color: "transparent"
        surfaceFormat.opaque: false
        focusable: false
        exclusiveZone: 0

        anchors.top: true
        anchors.right: true

        margins.top: Math.round((Config.Config.bar.size?.marginTop ?? 0) + root.barThickness - root.barCornerRadius + root.popdownOffset)
        margins.right: Math.max(0, Math.round(QSWindow.window ? (QSWindow.window.width - (root.pillRect.x + root.pillRect.width)) : 0))

        implicitWidth: root.popdownWidth
        implicitHeight: root.popdownHeight

        mask: Region {
            item: popdownWrapper
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
            height: implicitHeight
            implicitWidth: root.popdownWidth
            implicitHeight: 0
            clip: true
            visible: root.popdownOpen || implicitHeight > 0

            anchors.top: parent.top

            states: State {
                name: "open"
                when: root.popdownOpen

                PropertyChanges {
                    popdownWrapper.implicitHeight: root.popdownHeight
                }
            }

            transitions: [
                Transition {
                    from: ""
                    to: "open"

                    Anim {
                        target: popdownWrapper
                        property: "implicitHeight"
                        durationMs: Config.Motion.shellDuration
                        curve: Config.Motion.shellCurve
                    }
                },
                Transition {
                    from: "open"
                    to: ""

                    Anim {
                        target: popdownWrapper
                        property: "implicitHeight"
                        durationMs: Config.Motion.shortDuration
                        curve: Config.Motion.standardCurve
                    }
                }
            ]

            Item {
                id: popdownSurface

                width: root.popdownWidth
                height: root.popdownHeight
                anchors.top: parent.top

                Rectangle {
                    id: popdownBody

                    anchors.fill: parent
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
                    id: leftEdgeArc

                    visible: root.barCornerRadius > 0
                    radius: root.barCornerRadius
                    fillColor: popdownBody.color
                    anchors.right: popdownBody.left
                    anchors.top: popdownBody.top
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

                Rectangle {
                    id: placeholderButton

                    width: parent.width - root.popdownPadding * 2
                    height: Math.max(32, Math.round(root.barHeight * 1.4))
                    radius: Config.Appearance.radiusSmall
                    color: Config.Palette.color("surface_container_high")

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: root.popdownPadding
                    anchors.leftMargin: root.popdownPadding
                    z: 2

                    Text {
                        anchors.centerIn: parent
                        text: "Button"
                        color: Config.Palette.color("on_surface")
                        font.family: Config.Appearance.fontFamily
                        font.weight: Config.Appearance.fontWeight
                        font.pixelSize: Config.Appearance.fontSizeMedium
                    }
                }
            }

            MouseArea {
                id: popdownHover
                anchors.fill: popdownBody
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onContainsMouseChanged: root.updatePopdownHold()
            }
        }
    }

    Timer {
        id: wifiTimer
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiProcess.exec(["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,DEVICE dev wifi; nmcli -t -f TYPE,STATE dev"])
    }

    Process {
        id: wifiProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (!output) {
                    root.wifiStrength = -1;
                    root.wifiConnected = false;
                    root.ethernetConnected = false;
                    return;
                }
                const lines = output.split("\n");
                let wifiStrength = -1;
                let wifiConnected = false;
                let ethernetConnected = false;
                for (const line of lines) {
                    if (!line) {
                        continue;
                    }
                    const parts = line.split(":");
                    if (parts.length === 3) {
                        const inUse = parts[0];
                        const signalValue = Number(parts[1]);
                        if (inUse === "*") {
                            wifiConnected = true;
                            if (!Number.isNaN(signalValue)) {
                                wifiStrength = Math.max(0, Math.min(100, signalValue));
                            }
                        }
                        continue;
                    }
                    if (parts.length === 2) {
                        const typeValue = parts[0];
                        const stateValue = parts[1];
                        if (typeValue === "ethernet" && stateValue === "connected") {
                            ethernetConnected = true;
                        }
                    }
                }
                root.wifiStrength = wifiStrength;
                root.wifiConnected = wifiConnected;
                root.ethernetConnected = ethernetConnected;
            }
        }
    }
}
