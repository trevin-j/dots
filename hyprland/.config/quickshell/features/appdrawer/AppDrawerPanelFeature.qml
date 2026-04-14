import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../config" as Config
import "../../design/primitives" as Primitives
import "./components" as AppDrawerComponents
import "./vm" as AppDrawerVm

/*
  AppDrawerPanelFeature
  Full-width bottom-edge app drawer with search, grid pagination, and global key capture.
  Required properties: panelScreen, state.
*/
Primitives.SlideOutPanelWindow {
    id: root

    required property AppDrawerVm.AppDrawerState state

    readonly property int contentPadding: Config.Config.appDrawer?.size?.padding ?? 18
    readonly property int contentSpacing: Config.Config.appDrawer?.size?.spacing ?? 14
    readonly property int searchHeight: Config.Config.appDrawer?.size?.searchHeight ?? 44
    readonly property int searchHorizontalPadding: Config.Config.appDrawer?.size?.searchHorizontalPadding ?? 18
    readonly property int rows: Math.max(1, Config.Config.appDrawer?.size?.rows ?? 3)
    readonly property int columns: Math.max(1, Config.Config.appDrawer?.size?.columns ?? 10)
    readonly property int tileHeight: Config.Config.appDrawer?.size?.tileHeight ?? 104
    readonly property int tileSpacing: Config.Config.appDrawer?.size?.tileSpacing ?? 10
    readonly property int iconSize: Config.Config.appDrawer?.size?.iconSize ?? 38
    readonly property int pageControlHeight: Config.Config.appDrawer?.size?.pageControlHeight ?? 36
    readonly property int overshootBottomPadding: Config.Config.appDrawer?.size?.overshootPadding
        ?? Math.max(72, Math.round(root.panelHeight * 0.22))
    readonly property int drawerOpenDelay: Config.Config.appDrawer?.behavior?.drawerOpenDelay ?? 0
    readonly property int pagePreloadRadius: Math.max(0,
        Math.floor(Number(Config.Config.appDrawer?.behavior?.pagePreloadRadius ?? 1) || 1))
    readonly property real pageSwipeThreshold: Math.max(0.1, Math.min(0.9,
        Number(Config.Config.appDrawer?.behavior?.pageSwipeThreshold ?? 0.5)))
    readonly property real horizontalScrollSensitivity: Math.max(0.5,
        Number(Config.Config.appDrawer?.behavior?.horizontalScrollSensitivity ?? 2.4))
    readonly property int panelOpenDurationMs: Config.Motion.shellDuration
    readonly property int panelCloseDurationMs: Config.Motion.shortDuration
    readonly property color surfaceColor: Config.Palette.color("surface")
    readonly property color sectionColor: Config.Palette.color("surface_container")
    readonly property int gridHeight: rows * tileHeight + Math.max(0, rows - 1) * tileSpacing
    readonly property int panelHeight: contentPadding
        + searchHeight
        + contentSpacing
        + gridHeight
        + contentSpacing
        + pageControlHeight
        + contentPadding

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
        root.state.moveSelection(delta, appModel.totalItems, appModel.pageSize);
    }

    function selectPage(page) {
        pageSettleTimer.stop();
        pageFlick.pageGestureActive = false;
        root.state.selectPage(page, appModel.totalPages, appModel.pageSize, appModel.totalItems);
    }

    function beginPageGesture() {
        if (pageFlick.pageGestureActive) {
            return;
        }

        pageFlick.pageGestureActive = true;
        pageFlick.pageGestureAnchorPage = root.state.page;
    }

    function settlePageGesture() {
        if (pageFlick.width <= 0) {
            pageFlick.pageGestureActive = false;
            return;
        }

        const anchorPage = Math.max(0, Math.min(appModel.totalPages - 1, pageFlick.pageGestureAnchorPage));
        const anchorOffset = anchorPage * pageFlick.width;
        const progress = (pageFlick.contentX - anchorOffset) / pageFlick.width;
        let targetPage = anchorPage;

        if (progress >= root.pageSwipeThreshold) {
            targetPage += 1;
        } else if (progress <= -root.pageSwipeThreshold) {
            targetPage -= 1;
        }

        pageFlick.pageGestureActive = false;
        root.selectPage(targetPage);
    }

    function nudgePageGesture(delta) {
        if (pageFlick.width <= 0 || appModel.totalPages <= 1) {
            return;
        }

        root.beginPageGesture();
        const minX = Math.max(0, (pageFlick.pageGestureAnchorPage - 1) * pageFlick.width);
        const maxX = Math.min((appModel.totalPages - 1) * pageFlick.width,
            (pageFlick.pageGestureAnchorPage + 1) * pageFlick.width);
        pageFlick.contentX = Math.max(minX, Math.min(maxX, pageFlick.contentX + delta));
        pageSettleTimer.restart();
    }

    function launchSelectedApp() {
        if (!appModel.selectedItem) {
            return;
        }

        appModel.launchSelected();
        root.state.close();
    }

    function shouldLoadPage(pageIndex) {
        return Math.abs(pageIndex - root.state.page) <= root.pagePreloadRadius;
    }

    onVisibleChanged: {
        if (!visible) {
            focusRetryTimer.stop();
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

    Timer {
        id: pageSettleTimer

        interval: 90
        repeat: false
        onTriggered: root.settlePageGesture()
    }

    Connections {
        target: root.state

        function onOpenChanged() {
            if (root.state.open) {
                focusTimer.restart();
                focusRetryTimer.restart();
            } else {
                focusRetryTimer.stop();
            }
        }

        function onPageChanged() {
            const targetX = root.state.page * pageFlick.width;
            if (Math.abs(pageFlick.contentX - targetX) > 1) {
                pageFlick.contentX = targetX;
            }
            pageFlick.pageGestureAnchorPage = root.state.page;
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        height: Math.max(0, Math.round(mainPanel.visibleSurfaceY))
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.state.open
        onClicked: root.state.close()
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
                    anchors.fill: parent
                    anchors.margins: root.contentPadding

                    Flickable {
                        id: pageFlick

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: root.gridHeight
                        clip: true
                        contentWidth: Math.max(width, width * Math.max(1, appModel.totalPages))
                        contentHeight: height
                        interactive: appModel.totalPages > 1
                        flickableDirection: Flickable.HorizontalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        property int pageGestureAnchorPage: root.state.page
                        property bool pageGestureActive: false

                        onWidthChanged: contentX = root.state.page * width
                        onMovementStarted: root.beginPageGesture()
                        onDraggingChanged: if (!dragging) {
                            pageSettleTimer.restart();
                        }
                        onFlickingChanged: if (!flicking && !dragging) {
                            pageSettleTimer.restart();
                        }

                        Behavior on contentX {
                            enabled: !pageFlick.dragging && !pageFlick.flicking

                            NumberAnimation {
                                duration: Config.Motion.shellDuration
                                easing.bezierCurve: Config.Motion.shell
                            }
                        }

                        onMovementEnded: {
                            pageSettleTimer.restart();
                        }

                        WheelHandler {
                            target: pageFlick
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                            onWheel: event => {
                                if (!root.state.open || appModel.totalPages <= 1) {
                                    return;
                                }

                                let delta = 0;
                                if (event.pixelDelta.x !== 0) {
                                    delta = -event.pixelDelta.x;
                                } else if (event.angleDelta.x !== 0) {
                                    delta = -(event.angleDelta.x / 120) * 48;
                                } else {
                                    return;
                                }

                                root.nudgePageGesture(delta * root.horizontalScrollSensitivity);
                                event.accepted = true;
                            }
                        }

                        Repeater {
                            model: Math.max(1, appModel.totalPages)

                            delegate: Item {
                                required property int index

                                x: index * pageFlick.width
                                width: pageFlick.width
                                height: pageFlick.height

                                Loader {
                                    anchors.fill: parent
                                    active: root.shouldLoadPage(index)
                                    asynchronous: true

                                    sourceComponent: AppDrawerComponents.AppDrawerGrid {
                                        items: appModel.pageItems(index)
                                        columns: root.columns
                                        tileHeight: root.tileHeight
                                        iconSize: root.iconSize
                                        tileSpacing: root.tileSpacing
                                        model: appModel
                                        selectedPageIndex: root.state.selectedIndex - appModel.pageStartIndex(index)
                                        onAppActivated: desktopId => {
                                            appModel.launch(desktopId);
                                            root.state.close();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    AppDrawerComponents.AppDrawerPagination {
                        page: root.state.page
                        pageCount: appModel.totalPages
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        height: root.pageControlHeight
                        onPageRequested: page => root.selectPage(page)
                    }
                }
            }
        }
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

            if (event.key === Qt.Key_Escape) {
                root.state.close();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Left || event.key === Qt.Key_PageUp) {
                if (event.key === Qt.Key_PageUp) {
                    root.selectPage(root.state.page - 1);
                } else {
                    root.moveSelection(-1);
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Right || event.key === Qt.Key_PageDown) {
                if (event.key === Qt.Key_PageDown) {
                    root.selectPage(root.state.page + 1);
                } else {
                    root.moveSelection(1);
                }
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
