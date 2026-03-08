import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../../../config" as Config
import "../../../design/primitives" as Primitives
import "../../../utils"

/*
  WhichKeyPopup
  Renders the which-key overlay with OSD-matched chrome and keyboard navigation.
  Required properties: active, viewModel, style.
*/
PanelWindow {
    id: root

    required property bool active
    required property var viewModel
    required property var style

    property string bubbleColorRole: "surface"
    property string attachEdge: "bottom"

    readonly property int popupWidth: style?.width ?? 860
    readonly property int popupPadding: style?.padding ?? 18
    readonly property int popupSpacing: style?.spacing ?? 12
    readonly property int columns: Math.max(1, style?.columns ?? 2)
    readonly property int columnSpacing: style?.columnSpacing ?? 12
    readonly property int rowSpacing: style?.rowSpacing ?? 8
    readonly property int itemHeight: style?.itemHeight ?? 44
    readonly property int iconSize: style?.iconSize ?? 18
    readonly property int keySize: style?.keySize ?? 13
    readonly property real maxHeightRatio: style?.maxHeightRatio ?? 0.72
    readonly property real cornerRadius: Config.Appearance.radiusLarge
    readonly property int maxBodyHeight: Math.round((root.screen?.height || 1080) * root.maxHeightRatio)

    function keyFromEvent(event) {
        if (!event) {
            return "";
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            return "<enter>";
        }

        const text = typeof event.text === "string" ? event.text.trim().toLowerCase() : "";
        if (/^[a-z0-9]$/.test(text)) {
            return text;
        }
        return "";
    }

    function dispatchEntryKey(key) {
        if (!key) {
            return;
        }
        root.viewModel.activateEntry(key);
    }

    anchors.bottom: true
    margins.bottom: 0
    exclusiveZone: 0

    focusable: root.active
    visible: true
    color: "transparent"
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "quickshell-whichkey"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    implicitWidth: popupWrapper.implicitWidth
    implicitHeight: popupContainer.implicitHeight

    mask: Region {
        item: popupWrapper
    }

    onActiveChanged: {
        if (active) {
            focusTimer.restart();
            focusRetryTimer.restart();
        } else {
            focusRetryTimer.stop();
        }
    }

    onVisibleChanged: {
        if (visible && active) {
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer

        interval: 0
        repeat: false
        onTriggered: keyRouter.forceActiveFocus()
    }

    Timer {
        id: focusRetryTimer

        interval: 70
        repeat: false
        onTriggered: {
            if (root.active) {
                keyRouter.forceActiveFocus();
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab

        windows: [root]
        active: root.active && root.visible

        onCleared: {
            if (root.active) {
                root.viewModel.close();
            }
        }
    }

    Primitives.SurfaceShadow {
        source: popupWrapper
        enabled: Config.Appearance.shadowEnabled && (root.active || popupWrapper.implicitHeight > 0)
    }

    Primitives.FrameWrapper {
        id: popupWrapper

        screen: root.screen
        attachEdge: root.attachEdge
        active: root.active
        bubbleColorRole: root.bubbleColorRole

        width: implicitWidth
        height: implicitHeight
        implicitWidth: root.popupWidth + root.cornerRadius * 2
        implicitHeight: 0
        clip: true
        visible: root.active || implicitHeight > 0

        anchors.bottom: parent.bottom

        states: State {
            name: "open"
            when: root.active

            PropertyChanges {
                popupWrapper.implicitHeight: popupContainer.implicitHeight
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "open"

                Anim {
                    target: popupWrapper
                    property: "implicitHeight"
                    durationMs: Config.Motion.shellDuration
                    curve: Config.Motion.shellCurve
                }
            },
            Transition {
                from: "open"
                to: ""

                Anim {
                    target: popupWrapper
                    property: "implicitHeight"
                    durationMs: Config.Motion.shortDuration
                    curve: Config.Motion.standardCurve
                }
            }
        ]

        Rectangle {
            id: popupContainer

            width: root.popupWidth
            x: root.cornerRadius
            anchors.bottom: parent.bottom
            radius: root.cornerRadius
            color: Config.Palette.color(root.bubbleColorRole)
            implicitHeight: Math.min(root.maxBodyHeight, contentColumn.implicitHeight + root.popupPadding * 2)

            Rectangle {
                width: root.cornerRadius
                height: root.cornerRadius
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                color: parent.color
            }

            Rectangle {
                width: root.cornerRadius
                height: root.cornerRadius
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: parent.color
            }

            ColumnLayout {
                id: contentColumn

                anchors.fill: parent
                anchors.leftMargin: root.popupPadding
                anchors.topMargin: root.popupPadding
                anchors.bottomMargin: root.popupPadding
                anchors.rightMargin: root.popupPadding
                spacing: root.popupSpacing

                Text {
                    text: root.viewModel.crumb
                    color: Config.Palette.color("on_surface_variant")
                    font.family: Config.Appearance.fontFamily
                    font.pixelSize: Config.Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Flickable {
                    id: listFlick

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(contentGrid.implicitHeight, root.maxBodyHeight - 96)
                    contentWidth: width
                    contentHeight: contentGrid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    GridLayout {
                        id: contentGrid

                        width: listFlick.width
                        columns: root.columns
                        rowSpacing: root.rowSpacing
                        columnSpacing: root.columnSpacing

                        Repeater {
                            model: root.viewModel.entries

                            delegate: Rectangle {
                                id: delegateRoot

                                required property var modelData

                                readonly property string bindKey: modelData.key || ""
                                readonly property string bindLabel: modelData.label || ""
                                readonly property string bindDescription: modelData.description || ""
                                readonly property string bindIcon: modelData.icon || "bolt"
                                readonly property bool bindHasChildren: modelData.hasChildren ?? false
                                readonly property bool bindLabelIsIcon: bindKey === "<enter>"

                                Layout.fillWidth: true
                                Layout.preferredHeight: root.itemHeight
                                radius: Config.Appearance.radiusMedium
                                color: Config.Palette.color("surface_container")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: delegateRoot.bindIcon
                                        color: Config.Palette.color("on_surface_variant")
                                        font.family: Config.Appearance.iconFontFamily
                                        font.pixelSize: root.iconSize
                                        font.weight: Font.Medium
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: delegateRoot.bindLabelIsIcon ? 34 : 28
                                        Layout.preferredHeight: delegateRoot.bindLabelIsIcon ? 24 : 22
                                        radius: 6
                                        color: Config.Palette.color("surface_container_high")
                                        border.width: 1
                                        border.color: Config.Palette.color("outline_variant")

                                        Text {
                                            anchors.centerIn: parent
                                            text: delegateRoot.bindLabel
                                            color: Config.Palette.color("on_surface")
                                            font.family: delegateRoot.bindLabelIsIcon
                                                ? Config.Appearance.iconFontFamily
                                                : Config.Appearance.fontFamily
                                            font.pixelSize: delegateRoot.bindLabelIsIcon
                                                ? Math.max(root.keySize + 1, 16)
                                                : root.keySize
                                            font.weight: delegateRoot.bindLabelIsIcon ? Font.Medium : Font.DemiBold
                                        }
                                    }

                                    Text {
                                        text: delegateRoot.bindDescription
                                        color: Config.Palette.color("on_surface")
                                        font.family: Config.Appearance.fontFamily
                                        font.pixelSize: Config.Appearance.fontSizeMedium
                                        font.weight: Config.Appearance.fontWeight
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        visible: delegateRoot.bindHasChildren
                                        text: "chevron_right"
                                        color: Config.Palette.color("on_surface_variant")
                                        font.family: Config.Appearance.iconFontFamily
                                        font.pixelSize: root.iconSize
                                        font.weight: Font.Medium
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.dispatchEntryKey(parent.bindKey)
                                }
                            }
                        }
                    }
                }
            }
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: popupContainer.color
            mirrorX: true
            mirrorY: true
            anchors.right: popupContainer.left
            anchors.bottom: popupContainer.bottom
        }

        Primitives.CornerCutout {
            visible: root.cornerRadius > 0
            radius: root.cornerRadius
            fillColor: popupContainer.color
            mirrorY: true
            anchors.left: popupContainer.right
            anchors.bottom: popupContainer.bottom
        }
    }

    Item {
        id: keyRouter

        anchors.fill: parent
        focus: root.active

        Keys.onPressed: event => {
            if (!root.active) {
                return;
            }

            if (event.key === Qt.Key_Escape) {
                root.viewModel.close();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Backspace) {
                root.viewModel.back();
                event.accepted = true;
                return;
            }

            const key = root.keyFromEvent(event);
            if (key) {
                root.dispatchEntryKey(key);
                event.accepted = true;
                return;
            }

            if (root.viewModel.closeOnUnknown) {
                root.viewModel.close();
                event.accepted = true;
            }
        }
    }

}
