import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../config" as Config
import "../primitives" as Primitives

/*
  SlideOutListPanel
  Full-height left-edge searchable list panel using app-drawer sizing tokens.
  Required properties: panelScreen, state, items, panelNamespace.
 */
Primitives.SlideOutPanelWindow {
    id: root

    required property var state
    required property var items
    required property string panelNamespace

    property string emptyText: "No items"
    property string headerStatusText: ""
    property int itemHeight: 60
    property int itemSpacing: 8
    property int itemIconSize: 18

    signal activateRequested(var item)

    readonly property int contentPadding: Config.Config.appDrawer?.size?.padding ?? 24
    readonly property int contentSpacing: Config.Config.appDrawer?.size?.spacing ?? 24
    readonly property int searchHeight: Config.Config.appDrawer?.size?.searchHeight ?? 54
    readonly property int searchHorizontalPadding: Config.Config.appDrawer?.size?.searchHorizontalPadding ?? 18
    readonly property int drawerOpenDelay: Config.Config.appDrawer?.behavior?.drawerOpenDelay ?? 0
    readonly property int overshootLeftPadding: Config.Config.appDrawer?.size?.overshootPadding
        ?? Math.max(64, Math.round(panelWidth * 0.24))
    readonly property int panelCloseDurationMs: Config.Motion.shortDuration
    readonly property color surfaceColor: Config.Palette.color("surface")
    readonly property color sectionColor: Config.Palette.color("surface_container")
    readonly property int panelWidth: Math.max(280, Math.round(Config.Config.appDrawer?.size?.width ?? 482))
    readonly property int totalItems: Array.isArray(root.items) ? root.items.length : 0
    readonly property var selectedItem: (root.state?.selectedIndex >= 0 && root.state?.selectedIndex < root.totalItems)
        ? root.items[root.state.selectedIndex]
        : null

    open: root.state?.open ?? false
    closeDurationMs: root.panelCloseDurationMs
    focusable: true
    WlrLayershell.namespace: root.panelNamespace
    WlrLayershell.keyboardFocus: root.state?.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function moveSelection(delta) {
        if (!root.state || typeof root.state.moveSelection !== "function") {
            return;
        }

        root.state.moveSelection(delta, root.totalItems, 1);
    }

    function activateSelected() {
        if (!root.selectedItem) {
            return;
        }

        root.activateRequested(root.selectedItem);
    }

    function ensureSelectedVisible() {
        if (!root.state || root.state.selectedIndex < 0 || root.state.selectedIndex >= listView.count) {
            return;
        }

        listView.positionViewAtIndex(root.state.selectedIndex, ListView.Contain);
    }

    function closePanel() {
        if (root.state && typeof root.state.close === "function") {
            root.state.close();
        }
    }

    onVisibleChanged: {
        if (!visible) {
            focusRetryTimer.stop();
        }
    }

    onItemsChanged: {
        if (root.state && typeof root.state.ensureSelectionInRange === "function") {
            root.state.ensureSelectionInRange(root.totalItems);
        }
        root.ensureSelectedVisible();
    }

    Keys.onPressed: event => {
        if (!root.state?.open) {
            return;
        }

        if (event.key === Qt.Key_Escape) {
            root.closePanel();
            event.accepted = true;
        }
    }

    Timer {
        id: focusTimer

        interval: 0
        repeat: false
        onTriggered: {
            keyRouter.forceActiveFocus();
            searchInput.forceInputFocus();
            searchInput.cursorAtEnd();
        }
    }

    Timer {
        id: focusRetryTimer

        interval: 70
        repeat: false
        onTriggered: {
            if (root.state?.open) {
                keyRouter.forceActiveFocus();
                searchInput.forceInputFocus();
                searchInput.cursorAtEnd();
            }
        }
    }

    Connections {
        target: root.state

        function onOpenChanged() {
            if (root.state.open) {
                focusTimer.restart();
                focusRetryTimer.restart();
                root.ensureSelectedVisible();
            } else {
                focusRetryTimer.stop();
            }
        }

        function onQueryChanged() {
            const next = root.state?.query ?? "";
            if (searchTextInput.text !== next) {
                searchTextInput.text = next;
            }
        }

        function onSelectedIndexChanged() {
            root.ensureSelectedVisible();
        }
    }

    MouseArea {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: Math.max(0, Math.round(mainPanel.visibleSurfaceX + mainPanel.edgeInset))
        width: Math.max(0, Math.round(parent.width - x))
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.state?.open ?? false
        onClicked: root.closePanel()
    }

    Primitives.SlideOutPanelSurface {
        id: mainPanel

        anchors.fill: parent
        attachedEdge: "left"
        primaryExtent: root.panelWidth
        overshootPadding: root.overshootLeftPadding
        openDelay: root.drawerOpenDelay
        active: root.presentationOpen
        open: root.open
        surfaceColor: root.surfaceColor
        shadowOffsetX: 6

        onEdgeInsetChanged: {
            if (root.state && root.state.edgeInset !== undefined) {
                root.state.edgeInset = edgeInset;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.contentPadding
            spacing: root.contentSpacing

            Rectangle {
                id: searchInput

                Layout.fillWidth: true
                Layout.preferredHeight: root.searchHeight
                Layout.leftMargin: root.searchHorizontalPadding
                Layout.rightMargin: root.searchHorizontalPadding
                radius: height / 2
                color: Config.Palette.color("surface_container")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.max(12, Math.round(parent.height * 0.42))
                    anchors.rightMargin: Math.max(12, Math.round(parent.height * 0.42))
                    spacing: Math.max(8, Math.round(parent.height * 0.18))

                    Text {
                        text: "search"
                        font.family: Config.Appearance.iconFontFamily
                        font.pixelSize: Math.max(16, Math.round(Config.Appearance.fontSizeLarge))
                        font.weight: Font.Medium
                        color: Config.Palette.color("on_surface_variant")
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
                        id: searchTextInput

                        text: root.state?.query ?? ""
                        clip: true
                        color: Config.Palette.color("on_surface")
                        selectedTextColor: Config.Palette.color("on_primary")
                        selectionColor: Config.Palette.color("primary")
                        font.family: Config.Appearance.fontFamily
                        font.weight: Config.Appearance.fontWeight
                        font.pixelSize: Config.Appearance.fontSizeMedium
                        verticalAlignment: TextInput.AlignVCenter
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        onTextEdited: {
                            if (root.state && typeof root.state.setQuery === "function") {
                                root.state.setQuery(searchTextInput.text);
                            }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.closePanel();
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                                root.moveSelection(-1);
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                                root.moveSelection(1);
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.activateSelected();
                                event.accepted = true;
                            }
                        }
                    }

                    Text {
                        visible: root.headerStatusText !== ""
                        text: root.headerStatusText
                        color: Config.Palette.color("on_surface_variant")
                        font.family: Config.Appearance.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: Config.Appearance.fontSizeSmall
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                function forceInputFocus() {
                    searchTextInput.forceActiveFocus();
                }

                function cursorAtEnd() {
                    searchTextInput.cursorPosition = searchTextInput.text.length;
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

                    ListView {
                        id: listView

                        anchors.fill: parent
                        model: root.items
                        clip: true
                        spacing: root.itemSpacing
                        boundsBehavior: Flickable.StopAtBounds
                        reuseItems: true
                        cacheBuffer: Math.max(root.itemHeight * 8, root.itemHeight * 4)

                        delegate: Rectangle {
                            id: rowRoot

                            required property int index
                            required property var modelData

                            readonly property var itemData: modelData ?? ({})
                            readonly property bool selected: index === root.state?.selectedIndex
                            readonly property bool hasDescription: (itemData.description || "") !== ""
                            readonly property bool hasIcon: (itemData.icon || "") !== ""

                            width: listView.width
                            height: root.itemHeight
                            radius: Config.Appearance.radiusMedium
                            color: rowRoot.selected
                                ? Config.Palette.color("secondary_container")
                                : (rowMouseArea.pressed || rowMouseArea.containsMouse
                                    ? Config.Palette.color("surface_container_high")
                                    : "transparent")
                            border.width: rowRoot.selected ? 1 : 0
                            border.color: rowRoot.selected ? Config.Palette.color("outline_variant") : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.Motion.shortDuration
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                Text {
                                    visible: rowRoot.hasIcon
                                    text: rowRoot.itemData.icon || ""
                                    color: Config.Palette.color("on_surface_variant")
                                    font.family: Config.Appearance.iconFontFamily
                                    font.pixelSize: root.itemIconSize
                                    font.weight: Font.Medium
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: rowRoot.hasDescription ? 2 : 0

                                    Text {
                                        text: rowRoot.itemData.label || ""
                                        color: Config.Palette.color("on_surface")
                                        font.family: Config.Appearance.fontFamily
                                        font.weight: rowRoot.selected ? Font.DemiBold : Config.Appearance.fontWeight
                                        font.pixelSize: Config.Appearance.fontSizeMedium
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: rowRoot.hasDescription ? 1 : 2
                                        wrapMode: rowRoot.hasDescription ? Text.NoWrap : Text.WordWrap
                                    }

                                    Text {
                                        visible: rowRoot.hasDescription
                                        text: rowRoot.itemData.description || ""
                                        color: Config.Palette.color("on_surface_variant")
                                        font.family: Config.Appearance.fontFamily
                                        font.weight: Config.Appearance.fontWeight
                                        font.pixelSize: Config.Appearance.fontSizeSmall
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouseArea

                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (root.state) {
                                        root.state.selectedIndex = rowRoot.index;
                                    }
                                    root.activateRequested(rowRoot.itemData);
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            width: Math.max(120, parent.width - root.contentPadding * 2)
                            visible: root.totalItems === 0
                            text: root.emptyText
                            color: Config.Palette.color("on_surface_variant")
                            font.family: Config.Appearance.fontFamily
                            font.pixelSize: Config.Appearance.fontSizeMedium
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }

    Item {
        id: keyRouter

        anchors.fill: parent
        focus: root.state?.open ?? false

        function hasBlockedModifiers(event) {
            const modifiers = event.modifiers || 0;
            return !!(modifiers & Qt.ControlModifier)
                || !!(modifiers & Qt.AltModifier)
                || !!(modifiers & Qt.MetaModifier);
        }

        function appendPrintable(text) {
            const printable = typeof text === "string" ? text : "";
            if (!printable || printable < " ") {
                return false;
            }

            if (!root.state || typeof root.state.setQuery !== "function") {
                return false;
            }

            root.state.setQuery((root.state.query || "") + printable);
            searchInput.forceInputFocus();
            searchInput.cursorAtEnd();
            return true;
        }

        Keys.onPressed: event => {
            if (!root.state?.open) {
                return;
            }

            if (event.key === Qt.Key_Escape) {
                root.closePanel();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                root.moveSelection(-1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                root.moveSelection(1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Backspace) {
                root.state.setQuery((root.state.query || "").slice(0, Math.max(0, (root.state.query || "").length - 1)));
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Delete) {
                root.state.setQuery("");
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activateSelected();
                event.accepted = true;
                return;
            }

            if (!keyRouter.hasBlockedModifiers(event) && keyRouter.appendPrintable(event.text)) {
                event.accepted = true;
            }
        }
    }
}
