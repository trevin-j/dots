import QtQuick
import QtTest

import "../../../features/appdrawer/vm/AppDrawerLogic.js" as AppDrawerLogic

TestCase {
    name: "AppDrawerLogic"

    function test_buildCacheAndFavoriteOrder() {
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
        const cached = AppDrawerLogic.buildCache(entries, ["a.desktop"], usage, 1000);
        const ranked = AppDrawerLogic.rankAndFilter(cached, "");

        compare(ranked.length, 2);
        compare(ranked[0].desktopId, "a.desktop");
        compare(ranked[1].desktopId, "b.desktop");
    }

    function test_sortBaseEntriesUsesFavoriteThenFrecency() {
        const ranked = AppDrawerLogic.sortBaseEntries([
            {
                desktopId: "browser.desktop",
                name: "Browser",
                favoriteRank: -1,
                frecency: 500
            },
            {
                desktopId: "notes.desktop",
                name: "Notes",
                favoriteRank: 1,
                frecency: 10
            },
            {
                desktopId: "terminal.desktop",
                name: "Terminal",
                favoriteRank: 0,
                frecency: 200
            }
        ]);

        compare(ranked.length, 3);
        compare(ranked[0].desktopId, "terminal.desktop");
        compare(ranked[1].desktopId, "notes.desktop");
        compare(ranked[2].desktopId, "browser.desktop");
    }

    function test_emptyQueryUsesBaseOrdering() {
        const cached = [
            {
                desktopId: "browser.desktop",
                name: "Browser",
                favoriteRank: -1,
                frecency: 100,
                searchText: "browser"
            },
            {
                desktopId: "archive.desktop",
                name: "Archive",
                favoriteRank: -1,
                frecency: 100,
                searchText: "archive"
            },
            {
                desktopId: "terminal.desktop",
                name: "Terminal",
                favoriteRank: 0,
                frecency: 1,
                searchText: "terminal"
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
                frecency: 0,
                searchText: "firefox web browser"
            },
            {
                desktopId: "thunderbird.desktop",
                iconName: "thunderbird",
                name: "Thunderbird",
                genericName: "",
                favoriteRank: -1,
                frecency: 0,
                searchText: "thunderbird email"
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
                frecency: 0,
                searchText: "firefox web browser"
            },
            {
                desktopId: "org.gnome.Nautilus.desktop",
                iconName: "org.gnome.Nautilus",
                name: "Files",
                genericName: "",
                favoriteRank: -1,
                frecency: 0,
                searchText: "files nautilus file manager"
            }
        ];

        const ranked = AppDrawerLogic.rankAndFilter(cached, "fbr");
        compare(ranked.length, 0);
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
