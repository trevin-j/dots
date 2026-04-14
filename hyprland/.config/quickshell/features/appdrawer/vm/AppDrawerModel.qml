pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "AppDrawerLogic.js" as AppDrawerLogic
import "./" as AppDrawerVm
import "../../../config" as Config
import "../../../services" as Services

/*
  AppDrawerModel
  Caches desktop entries and derives ranked paginated app-grid results.
  Required properties: state.
*/
QtObject {
    id: root

    required property AppDrawerVm.AppDrawerState state
    required property bool presentationOpen

    readonly property var appDrawerConfig: Config.Config.appDrawer ?? ({})
    readonly property int rows: AppDrawerLogic.normalizeRows(root.appDrawerConfig?.size?.rows)
    readonly property int columns: AppDrawerLogic.normalizeColumns(root.appDrawerConfig?.size?.columns)
    readonly property int pageSize: rows * columns
    readonly property var favorites: AppDrawerLogic.normalizeFavorites(root.appDrawerConfig?.favorites)
    readonly property var usageMap: Services.AppDrawerService.usageMap ?? ({})
    readonly property int searchDebounceMs: Math.max(0,
        Math.floor(Number(root.appDrawerConfig?.behavior?.searchDebounceMs ?? 35) || 35))

    property var sourceApplications: []
    property var cachedApps: []
    property var baseRankedApps: []
    property var sessionCachedApps: []
    property var sessionBaseRankedApps: []
    property var rankedApps: []
    property bool pendingSourceRefresh: false
    readonly property int totalItems: rankedApps.length
    readonly property int totalPages: AppDrawerLogic.pageCount(root.totalItems, root.pageSize)
    readonly property var currentPageItems: AppDrawerLogic.pageSlice(root.rankedApps, root.state.page, root.pageSize)
    readonly property var selectedItem: (root.state.selectedIndex >= 0 && root.state.selectedIndex < root.totalItems)
        ? root.rankedApps[root.state.selectedIndex]
        : null

    function snapshotApplications() {
        root.sourceApplications = AppDrawerLogic.asList(DesktopEntries.applications?.values);
    }

    function rebuildSourceCache() {
        root.pendingSourceRefresh = false;
        root.snapshotApplications();
        root.cachedApps = AppDrawerLogic.buildCache(
            root.sourceApplications,
            root.favorites,
            root.usageMap,
            Date.now()
        );
        root.baseRankedApps = AppDrawerLogic.sortBaseEntries(root.cachedApps);
        if (!root.state.open) {
            root.sessionCachedApps = root.cachedApps;
            root.sessionBaseRankedApps = root.baseRankedApps;
        }
        root.rebuildRanking();
    }

    function scheduleSourceRefresh() {
        root.pendingSourceRefresh = true;
        if (root.state.open) {
            return;
        }

        desktopRefreshTimer.restart();
    }

    function rebuildRanking() {
        rankingDebounceTimer.stop();
        if (!root.presentationOpen) {
            root.rankedApps = [];
            root.state.ensurePageInRange(1);
            return;
        }

        if (!root.state.query) {
            root.rankedApps = root.sessionBaseRankedApps;
        } else {
            root.rankedApps = AppDrawerLogic.rankAndFilter(root.sessionCachedApps, root.state.query);
        }
        root.state.ensureSelectionInRange(root.totalItems);
        root.state.ensurePageInRange(root.totalPages);
        root.state.syncPageToSelection(root.pageSize);
    }

    function scheduleRankingRefresh() {
        if (!root.presentationOpen) {
            root.rebuildRanking();
            return;
        }

        if (!root.state.query || root.searchDebounceMs === 0) {
            root.rebuildRanking();
            return;
        }

        rankingDebounceTimer.restart();
    }

    onFavoritesChanged: root.scheduleSourceRefresh()
    onPresentationOpenChanged: {
        if (root.presentationOpen) {
            return;
        }

        rankingDebounceTimer.stop();
        root.sessionCachedApps = [];
        root.sessionBaseRankedApps = [];
        root.rankedApps = [];
        if (root.pendingSourceRefresh) {
            desktopRefreshTimer.restart();
        }
    }
    onUsageMapChanged: root.scheduleSourceRefresh()

    property Timer desktopRefreshTimer: Timer {
        id: desktopRefreshTimer

        interval: 120
        repeat: false
        onTriggered: root.rebuildSourceCache()
    }

    property Timer rankingDebounceTimer: Timer {
        id: rankingDebounceTimer

        interval: root.searchDebounceMs
        repeat: false
        onTriggered: root.rebuildRanking()
    }

    property Connections desktopEntryConnections: Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.scheduleSourceRefresh();
        }
    }

    property Connections desktopEntryModelConnections: Connections {
        target: DesktopEntries.applications

        function onObjectInsertedPost() {
            root.scheduleSourceRefresh();
        }

        function onObjectRemovedPost() {
            root.scheduleSourceRefresh();
        }
    }

    property Connections queryConnections: Connections {
        target: root.state

        function onOpenChanged() {
            if (root.state.open) {
                if (root.pendingSourceRefresh || root.cachedApps.length === 0) {
                    root.rebuildSourceCache();
                }
                root.sessionCachedApps = root.cachedApps;
                root.sessionBaseRankedApps = root.baseRankedApps;
                root.rebuildRanking();
            } else if (!root.presentationOpen) {
                rankingDebounceTimer.stop();
                root.sessionCachedApps = [];
                root.sessionBaseRankedApps = [];
                root.rankedApps = [];
                if (root.pendingSourceRefresh) {
                    desktopRefreshTimer.restart();
                }
            }
        }

        function onQueryChanged() {
            root.scheduleRankingRefresh();
        }
    }

    Component.onCompleted: root.scheduleSourceRefresh()

    function iconSourceFor(iconName) {
        const normalized = typeof iconName === "string" ? iconName.trim() : "";
        if (!normalized) {
            return Quickshell.iconPath("image-missing", true);
        }

        return Quickshell.iconPath(normalized, true);
    }

    function pageItems(page) {
        return AppDrawerLogic.pageSlice(root.rankedApps, page, root.pageSize);
    }

    function pageStartIndex(page) {
        const index = Math.max(0, Math.floor(Number(page) || 0));
        return index * root.pageSize;
    }

    function launchSelected() {
        if (!root.selectedItem || !root.selectedItem.desktopId) {
            return;
        }

        root.launch(root.selectedItem.desktopId);
    }

    function launch(desktopId) {
        const id = typeof desktopId === "string" ? desktopId.trim() : "";
        if (!id) {
            return;
        }

        const source = AppDrawerLogic.asList(root.sessionCachedApps.length > 0 ? root.sessionCachedApps : root.cachedApps);
        for (const item of source) {
            if (!item || item.desktopId !== id || !item.entryRef) {
                continue;
            }

            item.entryRef.execute();
            Services.AppDrawerService.markLaunch(id);
            return;
        }

        Services.AppDrawerService.markLaunch(id);
    }
}
