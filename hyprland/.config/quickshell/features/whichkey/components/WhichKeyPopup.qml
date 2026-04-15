import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../../../config" as Config
import "../../../design/primitives" as Primitives

/*
  WhichKeyPopup
  Renders which-key content inside the same bottom slide-out drawer shell as app drawer.
  Required properties: panelScreen, active, viewModel, style.
 */
Primitives.SlideOutPanelWindow {
    id: root

    required property bool active
    required property var viewModel
    required property var style

    readonly property int contentPadding: Config.Config.appDrawer?.size?.padding ?? 18
    readonly property int contentSpacing: Config.Config.appDrawer?.size?.spacing ?? 14
    readonly property int headerHeight: Config.Config.appDrawer?.size?.searchHeight ?? 44
    readonly property int headerHorizontalPadding: Config.Config.appDrawer?.size?.searchHorizontalPadding ?? 18
    readonly property int drawerRows: Math.max(1, Config.Config.appDrawer?.size?.rows ?? 3)
    readonly property int drawerTileHeight: Config.Config.appDrawer?.size?.tileHeight ?? 104
    readonly property int drawerTileSpacing: Config.Config.appDrawer?.size?.tileSpacing ?? 10
    readonly property int footerHeight: 36
    readonly property int overshootBottomPadding: Config.Config.appDrawer?.size?.overshootPadding
        ?? Math.max(72, Math.round(root.panelHeight * 0.22))
    readonly property int drawerOpenDelay: Config.Config.appDrawer?.behavior?.drawerOpenDelay ?? 0
    readonly property int panelOpenDurationMs: Config.Motion.shellDuration
    readonly property int panelCloseDurationMs: Config.Motion.shortDuration
    readonly property color surfaceColor: Config.Palette.color("surface")
    readonly property color sectionColor: Config.Palette.color("surface_container")
    readonly property int sectionHeight: drawerRows * drawerTileHeight
        + Math.max(0, drawerRows - 1) * drawerTileSpacing
    readonly property int panelHeight: contentPadding
        + headerHeight
        + contentSpacing
        + sectionHeight
        + contentSpacing
        + footerHeight
        + contentPadding

    readonly property int columns: Math.max(1, style?.columns ?? 2)
    readonly property int columnSpacing: style?.columnSpacing ?? 12
    readonly property int rowSpacing: style?.rowSpacing ?? 8
    readonly property int itemHeight: style?.itemHeight ?? 44
    readonly property int iconSize: style?.iconSize ?? 18
    readonly property int keySize: style?.keySize ?? 13

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

    open: root.active
    closeDurationMs: root.panelCloseDurationMs
    focusable: true
    WlrLayershell.namespace: "quickshell-whichkey"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (!visible) {
            focusRetryTimer.stop();
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

    Connections {
        target: root

        function onOpenChanged() {
            if (root.open) {
                focusTimer.restart();
                focusRetryTimer.restart();
            } else {
                focusRetryTimer.stop();
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

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        height: Math.max(0, Math.round(mainPanel.visibleSurfaceY))
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.active
        onClicked: root.viewModel.close()
    }

    Primitives.SlideOutPanelSurface {
        id: mainPanel

        anchors.fill: parent
        attachedEdge: "bottom"
        primaryExtent: root.panelHeight
        overshootPadding: root.overshootBottomPadding
        openDelay: root.drawerOpenDelay
        active: root.presentationOpen
        open: root.open
        surfaceColor: root.surfaceColor
        shadowOffsetY: -Config.Appearance.shadowOffsetY

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.contentPadding
            spacing: root.contentSpacing

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.headerHeight
                Layout.leftMargin: root.headerHorizontalPadding
                Layout.rightMargin: root.headerHorizontalPadding

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    Text {
                        text: root.viewModel.title || "Leader"
                        color: Config.Palette.color("on_surface")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeLarge
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: root.viewModel.crumb
                        color: Config.Palette.color("on_surface_variant")
                        font.family: Config.Appearance.fontFamily
                        font.pixelSize: Config.Appearance.fontSizeSmall
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Config.Appearance.radiusLarge
                color: root.sectionColor
                clip: true

                Item {
                    anchors.fill: parent
                    anchors.margins: root.contentPadding

                    Flickable {
                        id: listFlick

                        anchors.fill: parent
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
                                    color: Config.Palette.color("surface_container_high")

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
                                            color: Config.Palette.color("surface_container")
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

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.footerHeight

                Text {
                    anchors.centerIn: parent
                    text: root.viewModel.path.length > 0 ? "Backspace back  Esc close" : "Esc close"
                    color: Config.Palette.color("on_surface_variant")
                    font.family: Config.Appearance.fontFamily
                    font.pixelSize: Config.Appearance.fontSizeSmall
                    font.weight: Font.Medium
                }
            }
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
