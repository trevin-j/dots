import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../config" as Config
import "../primitives" as Primitives

/*
  SlideOutGridPanel
  Full-height left-edge searchable grid panel using app-drawer sizing tokens.
  Required properties: panelScreen, state, items, panelNamespace.
 */
Primitives.SlideOutPanelWindow {
    id: root

    required property var state
    required property var items
    required property string panelNamespace

    property string emptyText: "No items"
    property int columns: 6
    property int tileHeight: 76
    property int tileSpacing: 12
    property int glyphSize: 30
    property string glyphFontFamily: ""

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

        root.state.moveSelection(delta, root.totalItems, root.columns);
    }

    function activateSelected() {
        if (!root.selectedItem) {
            return;
        }

        root.activateRequested(root.selectedItem);
    }

    function ensureSelectedVisible() {
        if (!root.state || root.state.selectedIndex < 0 || root.columns <= 0) {
            return;
        }

        const selectedRow = Math.floor(root.state.selectedIndex / root.columns);
        if (selectedRow < 0 || selectedRow >= gridList.count) {
            return;
        }

        gridList.positionViewAtIndex(selectedRow, ListView.Contain);
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

                            if (event.key === Qt.Key_Left) {
                                root.moveSelection(-1);
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Right) {
                                root.moveSelection(1);
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Up) {
                                root.moveSelection(-root.columns);
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Down) {
                                root.moveSelection(root.columns);
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.activateSelected();
                                event.accepted = true;
                            }
                        }
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

                    Item {
                        id: gridMetrics

                        anchors.fill: parent

                        readonly property real baseTileWidth: Math.max(52, Math.round(root.tileHeight * 0.78))
                        readonly property real baseGap: Math.max(8, root.tileSpacing)
                        readonly property real horizontalScale: width > 0
                            ? width / Math.max(1, root.columns * baseTileWidth + (root.columns + 1) * baseGap)
                            : 1
                        readonly property real columnGap: Math.max(8, baseGap * horizontalScale)
                        readonly property real sideGap: columnGap
                        readonly property real tileWidth: Math.max(1,
                            (width - sideGap * 2 - Math.max(0, root.columns - 1) * columnGap) / Math.max(1, root.columns))
                        readonly property real rowGap: Math.max(8, root.tileSpacing)
                        readonly property real topGap: rowGap
                        readonly property real bottomGap: rowGap
                        readonly property int totalRows: Math.ceil(root.totalItems / Math.max(1, root.columns))
                        readonly property real contentWidth: Math.max(0, width - sideGap * 2)

                        ListView {
                            id: gridList

                            anchors.fill: parent
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            orientation: ListView.Vertical
                            spacing: gridMetrics.rowGap
                            topMargin: gridMetrics.topGap
                            bottomMargin: gridMetrics.bottomGap
                            leftMargin: gridMetrics.sideGap
                            rightMargin: gridMetrics.sideGap
                            reuseItems: true
                            cacheBuffer: Math.max(root.tileHeight * 6, root.tileHeight * root.columns)
                            model: gridMetrics.totalRows
                            interactive: true

                            delegate: Item {
                                id: rowRoot

                                required property int index

                                width: gridMetrics.contentWidth
                                height: root.tileHeight

                                Repeater {
                                    model: root.columns

                                    delegate: Item {
                                        id: tileRoot

                                        required property int index

                                        readonly property int itemIndex: rowRoot.index * root.columns + index
                                        readonly property var itemData: itemIndex < root.totalItems ? root.items[itemIndex] : null
                                        readonly property bool selected: itemIndex === root.state?.selectedIndex

                                        visible: itemData !== null
                                        x: index * (gridMetrics.tileWidth + gridMetrics.columnGap)
                                        width: gridMetrics.tileWidth
                                        height: root.tileHeight

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Config.Appearance.radiusMedium
                                            color: tileRoot.selected
                                                ? Config.Palette.color("secondary_container")
                                                : (tileMouseArea.pressed || tileMouseArea.containsMouse
                                                    ? Config.Palette.color("surface_container_high")
                                                    : "transparent")
                                            border.width: tileRoot.selected ? 1 : 0
                                            border.color: tileRoot.selected ? Config.Palette.color("outline_variant") : "transparent"

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Config.Motion.shortDuration
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: tileRoot.itemData ? (tileRoot.itemData.glyph || "") : ""
                                            color: Config.Palette.color("on_surface")
                                            font.family: root.glyphFontFamily
                                            font.pixelSize: root.glyphSize
                                            font.weight: Font.Normal
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        MouseArea {
                                            id: tileMouseArea

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton
                                            onClicked: {
                                                if (root.state) {
                                                    root.state.selectedIndex = tileRoot.itemIndex;
                                                }
                                                if (tileRoot.itemData) {
                                                    root.activateRequested(tileRoot.itemData);
                                                }
                                            }
                                        }
                                    }
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

            if (event.key === Qt.Key_Left) {
                root.moveSelection(-1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Right) {
                root.moveSelection(1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Up) {
                root.moveSelection(-root.columns);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Down) {
                root.moveSelection(root.columns);
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
