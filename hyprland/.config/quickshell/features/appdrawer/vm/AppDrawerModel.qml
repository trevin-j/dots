pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "AppDrawerLogic.js" as AppDrawerLogic
import "./" as AppDrawerVm
import "../../../config" as Config
import "../../../services" as Services

/*
  AppDrawerModel
  Caches desktop entries and derives ranked app-grid results.
  Required properties: state.
*/
QtObject {
    id: root

    required property AppDrawerVm.AppDrawerState state
    required property bool presentationOpen

    readonly property var appDrawerConfig: Config.Config.appDrawer ?? ({})
    readonly property int rows: AppDrawerLogic.normalizeRows(root.appDrawerConfig?.size?.rows)
    readonly property int columns: AppDrawerLogic.normalizeColumns(root.appDrawerConfig?.size?.columns)
    readonly property var favorites: AppDrawerLogic.normalizeFavorites(root.appDrawerConfig?.favorites)
    readonly property var pinnedIds: Services.AppDrawerService.pinnedIds ?? []
    readonly property var hiddenIds: Services.AppDrawerService.hiddenIds ?? []
    readonly property bool showHidden: Services.AppDrawerService.showHidden ?? false
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
    property bool sourceCacheReady: false
    property bool sourceCacheBuilding: false
    readonly property int totalItems: rankedApps.length
    readonly property var selectedItem: (root.state.selectedIndex >= 0 && root.state.selectedIndex < root.totalItems)
        ? root.rankedApps[root.state.selectedIndex]
        : null

    function snapshotApplications() {
        root.sourceApplications = AppDrawerLogic.asList(DesktopEntries.applications?.values);
    }

    function rebuildSourceCache(syncSession) {
        if (root.sourceCacheBuilding) {
            return;
        }

        const shouldSyncSession = syncSession || !root.state.open || !root.sourceCacheReady;
        root.sourceCacheBuilding = true;
        root.pendingSourceRefresh = false;
        root.snapshotApplications();
        root.cachedApps = AppDrawerLogic.buildCache(
            root.sourceApplications,
            root.favorites,
            root.pinnedIds,
            root.hiddenIds,
            root.usageMap,
            Date.now()
        );
        root.baseRankedApps = AppDrawerLogic.sortBaseEntries(root.cachedApps);
        if (shouldSyncSession) {
            root.sessionCachedApps = root.cachedApps;
            root.sessionBaseRankedApps = root.baseRankedApps;
        }
        root.sourceCacheReady = true;
        root.sourceCacheBuilding = false;
        root.rebuildRanking();
        if (root.pendingSourceRefresh && !root.state.open) {
            desktopRefreshTimer.restart();
        }
    }

    function refreshUsageCache() {
        if (root.cachedApps.length === 0) {
            return;
        }

        root.cachedApps = AppDrawerLogic.updateUsageScores(root.cachedApps, root.usageMap, Date.now());
        root.baseRankedApps = AppDrawerLogic.sortBaseEntries(root.cachedApps);
        if (root.state.open) {
            root.sessionCachedApps = root.cachedApps;
            root.sessionBaseRankedApps = root.baseRankedApps;
        }
        root.rebuildRanking();
    }

    function scheduleSourceRefresh() {
        root.pendingSourceRefresh = true;
        if (root.sourceCacheBuilding || (root.state.open && root.sourceCacheReady)) {
            return;
        }

        desktopRefreshTimer.restart();
    }

    function rebuildRanking() {
        rankingDebounceTimer.stop();
        if (!root.presentationOpen) {
            root.rankedApps = [];
            root.state.ensureSelectionInRange(1);
            return;
        }

        if (!root.state.query) {
            root.rankedApps = AppDrawerLogic.filterVisibleEntries(root.sessionBaseRankedApps, root.showHidden);
        } else {
            root.rankedApps = AppDrawerLogic.filterVisibleEntries(
                AppDrawerLogic.rankAndFilter(root.sessionCachedApps, root.state.query),
                root.showHidden
            );
        }
        root.state.ensureSelectionInRange(root.totalItems);
    }

    function refreshCachedPreferences() {
        if (root.cachedApps.length === 0 && root.sourceApplications.length === 0) {
            root.scheduleSourceRefresh();
            return;
        }

        root.rebuildSourceCache(true);
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
    onPinnedIdsChanged: root.refreshCachedPreferences()
    onHiddenIdsChanged: root.refreshCachedPreferences()
    onShowHiddenChanged: root.rebuildRanking()
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
    onUsageMapChanged: root.refreshUsageCache()

    property Timer desktopRefreshTimer: Timer {
        id: desktopRefreshTimer

        interval: root.sourceCacheReady ? 120 : 0
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
                if (root.sourceCacheReady || root.cachedApps.length > 0) {
                    root.sessionCachedApps = root.cachedApps;
                    root.sessionBaseRankedApps = root.baseRankedApps;
                } else {
                    root.scheduleSourceRefresh();
                }
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
