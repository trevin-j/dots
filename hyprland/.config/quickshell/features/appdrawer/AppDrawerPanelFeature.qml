import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import "../../config" as Config
import "../../design/primitives" as Primitives
import "../../services" as Services
import "./components" as AppDrawerComponents
import "./vm" as AppDrawerVm

/*
  AppDrawerPanelFeature
  Full-height left-edge app drawer with search and vertical app grid.
  Required properties: panelScreen, state.
*/
Primitives.SlideOutPanelWindow {
    id: root

    required property AppDrawerVm.AppDrawerState state

    readonly property int contentPadding: Config.Config.appDrawer?.size?.padding ?? 24
    readonly property int contentSpacing: Config.Config.appDrawer?.size?.spacing ?? 24
    readonly property int searchHeight: Config.Config.appDrawer?.size?.searchHeight ?? 54
    readonly property int searchHorizontalPadding: Config.Config.appDrawer?.size?.searchHorizontalPadding ?? 18
    readonly property int columns: appModel.columns
    readonly property int tileHeight: Config.Config.appDrawer?.size?.tileHeight ?? 104
    readonly property int tileSpacing: Config.Config.appDrawer?.size?.tileSpacing ?? 20
    readonly property int iconSize: Config.Config.appDrawer?.size?.iconSize ?? 38
    readonly property int drawerOpenDelay: Config.Config.appDrawer?.behavior?.drawerOpenDelay ?? 0
    readonly property int overshootLeftPadding: Config.Config.appDrawer?.size?.overshootPadding
        ?? Math.max(64, Math.round(panelWidth * 0.24))
    readonly property int panelOpenDurationMs: Config.Motion.shellDuration
    readonly property int panelCloseDurationMs: Config.Motion.shortDuration
    readonly property color surfaceColor: Config.Palette.color("surface")
    readonly property color sectionColor: Config.Palette.color("surface_container")
    property string contextDesktopId: ""
    property bool contextPinned: false
    property bool contextHidden: false
    property string hoverTitle: ""
    property real hoverTooltipX: 0
    property real hoverTooltipY: 0
    readonly property int panelWidth: Math.max(280, Math.round(Config.Config.appDrawer?.size?.width ?? 482))

    open: root.state.open
    closeDurationMs: root.panelCloseDurationMs
    focusable: true
    WlrLayershell.namespace: "quickshell-appdrawer"
    WlrLayershell.keyboardFocus: root.state.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    AppDrawerVm.AppDrawerModel {
        id: appModel

        state: root.state
        presentationOpen: mainPanel.presentationOpen
    }

    function moveSelection(delta) {
        root.state.moveSelection(delta, appModel.totalItems, root.columns);
    }

    function launchSelectedApp() {
        if (!appModel.selectedItem) {
            return;
        }

        appModel.launchSelected();
        root.state.close();
    }

    function openContextMenu(tileItem, mouseX, mouseY, desktopId, pinned, hidden) {
        const point = tileItem.mapToItem(root.contentItem, mouseX, mouseY);
        const minX = Math.round(mainPanel.visibleSurfaceX + root.contentPadding);
        const maxX = Math.max(minX, Math.round(mainPanel.visibleSurfaceX + mainPanel.edgeInset - contextMenu.popupWidth - root.contentPadding));
        const minY = root.contentPadding;
        const maxY = Math.max(minY, Math.round(root.height - contextMenu.popupHeight - root.contentPadding));
        root.hideTitleTooltip();
        root.contextDesktopId = desktopId;
        root.contextPinned = pinned;
        root.contextHidden = hidden;
        contextMenu.menuX = Math.max(minX, Math.min(maxX, Math.round(point.x)));
        contextMenu.menuY = Math.max(minY, Math.min(maxY, Math.round(point.y)));
        contextMenu.open = true;
    }

    function closeContextMenu() {
        contextMenu.closeMenu();
    }

    function requestTitleTooltip(tileItem, title, anchorX, anchorY) {
        if (!title || contextMenu.open) {
            root.hideTitleTooltip();
            return;
        }

        const point = tileItem.mapToItem(root.contentItem, anchorX, anchorY);
        root.hoverTitle = title;
        const minX = Math.round(mainPanel.visibleSurfaceX + root.contentPadding);
        const maxX = Math.max(minX, Math.round(mainPanel.visibleSurfaceX + mainPanel.edgeInset - titleTooltip.bubbleWidth - root.contentPadding));
        const minY = root.contentPadding;
        const maxY = Math.max(minY, Math.round(root.height - titleTooltip.bubbleHeight - root.contentPadding));
        root.hoverTooltipX = Math.max(minX, Math.min(maxX, Math.round(point.x - titleTooltip.bubbleWidth / 2)));
        root.hoverTooltipY = Math.max(minY, Math.min(maxY, Math.round(point.y)));
        titleTooltipTimer.restart();
    }

    function hideTitleTooltip() {
        titleTooltipTimer.stop();
        titleTooltip.open = false;
        root.hoverTitle = "";
    }

    function ensureSelectedVisible() {
        if (root.state.selectedIndex < 0 || root.columns <= 0) {
            return;
        }

        const selectedRow = Math.floor(root.state.selectedIndex / root.columns);
        if (selectedRow < 0 || selectedRow >= appGrid.count) {
            return;
        }

        appGrid.positionViewAtIndex(selectedRow, ListView.Contain);
    }

    onVisibleChanged: {
        if (!visible) {
            focusRetryTimer.stop();
            root.closeContextMenu();
            root.hideTitleTooltip();
        }
    }

    Keys.onPressed: event => {
        if (!root.state.open) {
            return;
        }

        if (event.key === Qt.Key_Escape && contextMenu.open) {
            root.closeContextMenu();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Escape) {
            root.state.close();
            event.accepted = true;
        }
    }

    Timer {
        id: focusTimer

        interval: 0
        repeat: false
        onTriggered: {
            keyRouter.forceActiveFocus();
            searchPill.forceInputFocus();
            searchPill.cursorAtEnd();
        }
    }

    Timer {
        id: focusRetryTimer

        interval: 70
        repeat: false
        onTriggered: {
            if (root.state.open) {
                keyRouter.forceActiveFocus();
                searchPill.forceInputFocus();
                searchPill.cursorAtEnd();
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
                root.closeContextMenu();
                root.hideTitleTooltip();
                focusRetryTimer.stop();
            }
        }

        function onSelectedIndexChanged() {
            root.ensureSelectedVisible();
        }
    }

    Timer {
        id: titleTooltipTimer

        interval: 280
        repeat: false
        onTriggered: {
            titleTooltip.open = root.hoverTitle !== "" && !contextMenu.open;
        }
    }

    MouseArea {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: Math.max(0, Math.round(mainPanel.visibleSurfaceX + mainPanel.edgeInset))
        width: Math.max(0, Math.round(parent.width - x))
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.state.open
        onClicked: root.state.close()
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

        onEdgeInsetChanged: root.state.edgeInset = edgeInset

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.contentPadding
            spacing: root.contentSpacing

            AppDrawerComponents.AppDrawerSearchPill {
                id: searchPill

                query: root.state.query
                iconSize: Math.max(16, Math.round(Config.Appearance.fontSizeLarge))
                Layout.fillWidth: true
                Layout.preferredHeight: root.searchHeight
                Layout.leftMargin: root.searchHorizontalPadding
                Layout.rightMargin: root.searchHorizontalPadding
                onQueryEdited: value => root.state.setQuery(value)
                onEscapePressed: root.state.close()
                onLeftPressed: root.moveSelection(-1)
                onRightPressed: root.moveSelection(1)
                onUpPressed: root.moveSelection(-root.columns)
                onDownPressed: root.moveSelection(root.columns)
                onEnterPressed: root.launchSelectedApp()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Config.Appearance.radiusLarge
                color: root.sectionColor
                clip: true

                Item {
                    id: gridMetrics

                    anchors.fill: parent

                    readonly property real baseTileWidth: Math.max(56, Math.round(root.tileHeight * 0.78))
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
                    readonly property int totalRows: Math.ceil(appModel.totalItems / Math.max(1, root.columns))
                    readonly property real contentWidth: Math.max(0, width - sideGap * 2)

                    ListView {
                        id: appGrid

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
                        onContentYChanged: root.hideTitleTooltip()

                        WheelHandler {
                            target: appGrid
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                root.hideTitleTooltip();
                                let delta = 0;
                                if (event.pixelDelta.y !== 0) {
                                    delta = event.pixelDelta.y;
                                } else if (event.angleDelta.y !== 0) {
                                    delta = (event.angleDelta.y / 120) * 48;
                                }
                                const maxContentY = Math.max(0, appGrid.contentHeight - appGrid.height);
                                appGrid.contentY = Math.max(0, Math.min(maxContentY, appGrid.contentY - delta * 2));
                                event.accepted = true;
                            }
                        }

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

                                    readonly property int appIndex: rowRoot.index * root.columns + index
                                    readonly property var appData: appIndex < appModel.totalItems ? appModel.rankedApps[appIndex] : null
                                    readonly property string desktopId: appData?.desktopId || ""
                                    readonly property string iconName: appData?.iconName || ""
                                    readonly property string appName: appData?.name || desktopId
                                    readonly property string iconSource: appModel.iconSourceFor(iconName)
                                    readonly property real iconTopMargin: Math.max(6, Math.round(root.tileHeight * 0.08))
                                    readonly property real textTopMargin: Math.max(6, Math.round(root.tileHeight * 0.14))
                                    readonly property bool pinned: !!appData?.pinned
                                    readonly property bool hidden: !!appData?.hidden
                                    readonly property bool selected: appIndex === root.state.selectedIndex

                                    visible: appData !== null
                                    x: index * (gridMetrics.tileWidth + gridMetrics.columnGap)
                                    width: gridMetrics.tileWidth
                                    height: root.tileHeight

                                    Rectangle {
                                        id: tileBackground

                                        anchors.fill: parent
                                        radius: Config.Appearance.radiusMedium
                                        color: tileRoot.selected
                                            ? Config.Palette.color("secondary_container")
                                            : (mouseArea.pressed
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

                                    IconImage {
                                        source: tileRoot.iconSource
                                        asynchronous: true
                                        mipmap: true
                                        width: root.iconSize
                                        height: root.iconSize
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: tileRoot.iconTopMargin
                                    }

                                    Item {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.topMargin: tileRoot.iconTopMargin + root.iconSize + tileRoot.textTopMargin
                                        anchors.bottom: parent.bottom
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8

                                        Row {
                                            id: statusIcons

                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            spacing: 2
                                            visible: tileRoot.pinned || tileRoot.hidden

                                            Text {
                                                visible: tileRoot.pinned
                                                text: "push_pin"
                                                color: Config.Palette.color("on_surface_variant")
                                                font.family: Config.Appearance.iconFontFamily
                                                font.pixelSize: Math.max(12, Math.round(Config.Appearance.fontSizeSmall + 1))
                                                font.weight: Font.Medium
                                            }

                                            Text {
                                                visible: tileRoot.hidden
                                                text: "visibility_off"
                                                color: Config.Palette.color("on_surface_variant")
                                                font.family: Config.Appearance.iconFontFamily
                                                font.pixelSize: Math.max(12, Math.round(Config.Appearance.fontSizeSmall + 1))
                                                font.weight: Font.Medium
                                            }
                                        }

                                        Text {
                                            text: tileRoot.appName
                                            color: Config.Palette.color("on_surface")
                                            font.family: Config.Appearance.fontFamily
                                            font.weight: tileRoot.selected ? Font.DemiBold : Config.Appearance.fontWeight
                                            font.pixelSize: Config.Appearance.fontSizeSmall
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignTop
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            wrapMode: Text.WordWrap
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.rightMargin: statusIcons.visible ? statusIcons.width + 4 : 0
                                        }
                                    }

                                    MouseArea {
                                        id: mouseArea

                                        anchors.fill: parent
                                        acceptedButtons: Qt.AllButtons
                                        preventStealing: true
                                        hoverEnabled: true

                                        onEntered: {
                                            root.requestTitleTooltip(
                                                tileRoot,
                                                tileRoot.appName,
                                                tileRoot.width / 2,
                                                tileRoot.iconTopMargin + root.iconSize + tileRoot.textTopMargin
                                            );
                                        }

                                        onExited: root.hideTitleTooltip()

                                        onPressed: mouse => {
                                            root.hideTitleTooltip();
                                            if (mouse.button !== Qt.RightButton) {
                                                return;
                                            }

                                            root.state.selectedIndex = tileRoot.appIndex;
                                            root.openContextMenu(
                                                tileRoot,
                                                mouse.x,
                                                mouse.y,
                                                tileRoot.desktopId,
                                                tileRoot.pinned,
                                                tileRoot.hidden
                                            );
                                            mouse.accepted = true;
                                        }

                                        onClicked: mouse => {
                                            if (mouse.button !== Qt.LeftButton) {
                                                return;
                                            }

                                            root.state.selectedIndex = tileRoot.appIndex;
                                            root.launchSelectedApp();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    AppDrawerComponents.AppDrawerContextMenu {
        id: contextMenu

        anchors.fill: parent
        desktopId: root.contextDesktopId
        pinned: root.contextPinned
        hidden: root.contextHidden
        showHidden: appModel.showHidden

        onPinRequested: nextPinned => Services.AppDrawerService.setPinned(root.contextDesktopId, nextPinned)
        onHideRequested: nextHidden => Services.AppDrawerService.setHidden(root.contextDesktopId, nextHidden)
        onShowHiddenRequested: nextShowHidden => Services.AppDrawerService.setShowHidden(nextShowHidden)
        onDismissed: {
            root.contextDesktopId = "";
            root.contextPinned = false;
            root.contextHidden = false;
        }
    }

    AppDrawerComponents.AppDrawerTitleTooltip {
        id: titleTooltip

        anchors.fill: parent
        open: false
        title: root.hoverTitle
        tooltipX: root.hoverTooltipX
        tooltipY: root.hoverTooltipY
        maxWidth: Math.max(180, Math.round(root.panelWidth - root.contentPadding * 3))
    }

    Item {
        id: keyRouter

        anchors.fill: parent
        focus: root.state.open

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

            root.state.setQuery(root.state.query + printable);
            searchPill.forceInputFocus();
            searchPill.cursorAtEnd();
            return true;
        }

        Keys.onPressed: event => {
            if (!root.state.open) {
                return;
            }

            if (contextMenu.open && event.key === Qt.Key_Escape) {
                root.closeContextMenu();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Escape) {
                root.state.close();
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
                root.state.setQuery(root.state.query.slice(0, Math.max(0, root.state.query.length - 1)));
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Delete) {
                root.state.setQuery("");
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.launchSelectedApp();
                event.accepted = true;
                return;
            }

            if (!keyRouter.hasBlockedModifiers(event) && keyRouter.appendPrintable(event.text)) {
                event.accepted = true;
            }
        }
    }
}
