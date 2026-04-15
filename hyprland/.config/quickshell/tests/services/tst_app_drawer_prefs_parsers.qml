import QtQuick
import QtTest

import "../../services/parsers/AppDrawerPrefsParsers.js" as AppDrawerPrefsParsers

TestCase {
    name: "AppDrawerPrefsParsers"

    function test_normalizePrefsRemovesDuplicatesAndPinnedHiddenOverlap() {
        const prefs = AppDrawerPrefsParsers.normalizePrefs({
            pinnedIds: ["firefox.desktop", "firefox.desktop", "kitty.desktop"],
            hiddenIds: ["kitty.desktop", "org.gnome.Nautilus.desktop"],
            showHidden: 1
        });

        compare(prefs.pinnedIds.length, 1);
        compare(prefs.pinnedIds[0], "firefox.desktop");
        compare(prefs.hiddenIds.length, 2);
        compare(prefs.showHidden, true);
    }

    function test_setPinnedAddsVisibleApp() {
        const prefs = AppDrawerPrefsParsers.setPinned({
            pinnedIds: [],
            hiddenIds: [],
            showHidden: false
        }, "firefox.desktop", true);

        compare(prefs.pinnedIds.length, 1);
        compare(prefs.pinnedIds[0], "firefox.desktop");
    }

    function test_setHiddenRemovesPinnedState() {
        const prefs = AppDrawerPrefsParsers.setHidden({
            pinnedIds: ["firefox.desktop"],
            hiddenIds: [],
            showHidden: false
        }, "firefox.desktop", true);

        compare(prefs.pinnedIds.length, 0);
        compare(prefs.hiddenIds.length, 1);
        compare(prefs.hiddenIds[0], "firefox.desktop");
    }

    function test_parseAndStringifyPrefsRoundTrip() {
        const text = AppDrawerPrefsParsers.stringifyPrefs({
            pinnedIds: ["org.wezfurlong.wezterm.desktop"],
            hiddenIds: ["org.gnome.Calculator.desktop"],
            showHidden: true
        });
        const prefs = AppDrawerPrefsParsers.parsePrefsText(text);

        compare(prefs.pinnedIds[0], "org.wezfurlong.wezterm.desktop");
        compare(prefs.hiddenIds[0], "org.gnome.Calculator.desktop");
        compare(prefs.showHidden, true);
    }
}
