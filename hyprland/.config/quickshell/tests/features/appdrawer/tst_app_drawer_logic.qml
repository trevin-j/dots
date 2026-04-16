import QtQuick
import QtTest

import "../../../features/appdrawer/vm/AppDrawerLogic.js" as AppDrawerLogic

TestCase {
    name: "AppDrawerLogic"

    function test_buildCacheTracksPinnedAndHiddenState() {
        const entries = [
            {
                id: "b.desktop",
                name: "Bravo",
                genericName: "",
                comment: "",
                icon: "b",
                keywords: []
            },
            {
                id: "a.desktop",
                name: "Alpha",
                genericName: "",
                comment: "",
                icon: "a",
                keywords: []
            }
        ];
        const usage = {
            "b.desktop": { launches: 10, lastUsedMs: 1000 },
            "a.desktop": { launches: 1, lastUsedMs: 1000 }
        };
        const cached = AppDrawerLogic.buildCache(entries, ["a.desktop"], ["b.desktop"], ["a.desktop"], usage, 1000);

        compare(cached.length, 2);
        compare(cached[0].desktopId, "b.desktop");
        compare(cached[0].pinned, true);
        compare(cached[0].hidden, false);
        verify(cached[0].searchTokens.indexOf("bravo") >= 0);
        verify(cached[0].searchTokens.indexOf("desktop") >= 0);
        compare(cached[1].desktopId, "a.desktop");
        compare(cached[1].favoriteRank, 0);
        compare(cached[1].hidden, true);
    }

    function test_sortBaseEntriesUsesPinnedThenFrecency() {
        const ranked = AppDrawerLogic.sortBaseEntries([
            {
                desktopId: "browser.desktop",
                name: "Browser",
                favoriteRank: -1,
                pinned: false,
                frecency: 500
            },
            {
                desktopId: "notes.desktop",
                name: "Notes",
                favoriteRank: 1,
                pinned: true,
                frecency: 10
            },
            {
                desktopId: "terminal.desktop",
                name: "Terminal",
                favoriteRank: 0,
                pinned: true,
                frecency: 200
            }
        ]);

        compare(ranked.length, 3);
        compare(ranked[0].desktopId, "terminal.desktop");
        compare(ranked[1].desktopId, "notes.desktop");
        compare(ranked[2].desktopId, "browser.desktop");
    }

    function test_updateUsageScoresRefreshesFrecencyWithoutRebuildingEntries() {
        const entry = {
            entryRef: { id: "firefox" },
            desktopId: "firefox.desktop",
            iconName: "firefox",
            name: "Firefox",
            genericName: "Browser",
            comment: "",
            favoriteRank: -1,
            pinned: false,
            hidden: false,
            frecency: 0,
            launches: 0,
            lastUsedMs: 0,
            searchText: "firefox browser",
            searchTokens: ["firefox", "browser"]
        };

        const refreshed = AppDrawerLogic.updateUsageScores([
            entry
        ], {
            "firefox.desktop": {
                launches: 4,
                lastUsedMs: 3600000
            }
        }, 3600000);

        compare(refreshed.length, 1);
        compare(refreshed[0].desktopId, "firefox.desktop");
        compare(refreshed[0].entryRef, entry.entryRef);
        compare(refreshed[0].launches, 4);
        compare(refreshed[0].lastUsedMs, 3600000);
        compare(refreshed[0].searchTokens.length, 2);
        compare(refreshed[0].searchTokens[1], "browser");
        verify(refreshed[0].frecency > 0);
    }

    function test_buildCacheCombinesSearchTokensFromMetadata() {
        const cached = AppDrawerLogic.buildCache([
            {
                id: "org.mozilla.firefox.desktop",
                name: "Firefox",
                genericName: "Web Browser",
                comment: "Browse the web",
                icon: "firefox",
                keywords: ["internet", "mozilla"]
            }
        ], [], [], [], {}, 1000);

        compare(cached.length, 1);
        verify(cached[0].searchTokens.indexOf("firefox") >= 0);
        verify(cached[0].searchTokens.indexOf("web") >= 0);
        verify(cached[0].searchTokens.indexOf("browser") >= 0);
        verify(cached[0].searchTokens.indexOf("internet") >= 0);
        verify(cached[0].searchTokens.indexOf("mozilla") >= 0);
        verify(cached[0].searchTokens.indexOf("browse") >= 0);
        verify(cached[0].searchTokens.indexOf("org") >= 0);
        verify(cached[0].searchTokens.indexOf("desktop") >= 0);
    }

    function test_emptyQueryUsesBaseOrdering() {
        const cached = [
            {
                desktopId: "browser.desktop",
                name: "Browser",
                favoriteRank: -1,
                pinned: false,
                hidden: false,
                frecency: 100,
                searchText: "browser",
                searchTokens: ["browser"]
            },
            {
                desktopId: "archive.desktop",
                name: "Archive",
                favoriteRank: -1,
                pinned: false,
                hidden: false,
                frecency: 100,
                searchText: "archive",
                searchTokens: ["archive"]
            },
            {
                desktopId: "terminal.desktop",
                name: "Terminal",
                favoriteRank: 0,
                pinned: true,
                hidden: false,
                frecency: 1,
                searchText: "terminal",
                searchTokens: ["terminal"]
            }
        ];

        const ranked = AppDrawerLogic.rankAndFilter(cached, "");
        compare(ranked.length, 3);
        compare(ranked[0].desktopId, "terminal.desktop");
        compare(ranked[1].desktopId, "archive.desktop");
        compare(ranked[2].desktopId, "browser.desktop");
    }

    function test_fuzzyFilter() {
        const cached = [
            {
                desktopId: "firefox.desktop",
                iconName: "firefox",
                name: "Firefox",
                genericName: "",
                favoriteRank: -1,
                pinned: false,
                hidden: false,
                frecency: 0,
                searchText: "firefox web browser",
                searchTokens: ["firefox", "web", "browser"]
            },
            {
                desktopId: "thunderbird.desktop",
                iconName: "thunderbird",
                name: "Thunderbird",
                genericName: "",
                favoriteRank: -1,
                pinned: false,
                hidden: false,
                frecency: 0,
                searchText: "thunderbird email",
                searchTokens: ["thunderbird", "email"]
            }
        ];

        const ranked = AppDrawerLogic.rankAndFilter(cached, "ffx");
        compare(ranked.length, 1);
        compare(ranked[0].desktopId, "firefox.desktop");
    }

    function test_fuzzyFilterRejectsLooseMatches() {
        const cached = [
            {
                desktopId: "firefox.desktop",
                iconName: "firefox",
                name: "Firefox",
                genericName: "",
                favoriteRank: -1,
                pinned: false,
                hidden: false,
                frecency: 0,
                searchText: "firefox web browser",
                searchTokens: ["firefox", "web", "browser"]
            },
            {
                desktopId: "org.gnome.Nautilus.desktop",
                iconName: "org.gnome.Nautilus",
                name: "Files",
                genericName: "",
                favoriteRank: -1,
                pinned: false,
                hidden: false,
                frecency: 0,
                searchText: "files nautilus file manager",
                searchTokens: ["files", "nautilus", "file", "manager"]
            }
        ];

        const ranked = AppDrawerLogic.rankAndFilter(cached, "fbr");
        compare(ranked.length, 0);
    }

    function test_filterVisibleEntriesHidesHiddenAppsByDefault() {
        const filtered = AppDrawerLogic.filterVisibleEntries([
            { desktopId: "a.desktop", hidden: false },
            { desktopId: "b.desktop", hidden: true },
            { desktopId: "c.desktop", hidden: false }
        ], false);

        compare(filtered.length, 2);
        compare(filtered[0].desktopId, "a.desktop");
        compare(filtered[1].desktopId, "c.desktop");
    }

    function test_filterVisibleEntriesKeepsHiddenAppsWhenEnabled() {
        const filtered = AppDrawerLogic.filterVisibleEntries([
            { desktopId: "a.desktop", hidden: false },
            { desktopId: "b.desktop", hidden: true }
        ], true);

        compare(filtered.length, 2);
        compare(filtered[1].desktopId, "b.desktop");
    }

    function test_pageSlice() {
        const items = [
            { desktopId: "1" },
            { desktopId: "2" },
            { desktopId: "3" },
            { desktopId: "4" },
            { desktopId: "5" }
        ];
        const page = AppDrawerLogic.pageSlice(items, 1, 2);
        compare(page.length, 2);
        compare(page[0].desktopId, "3");
        compare(page[1].desktopId, "4");
    }
}
