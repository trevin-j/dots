import QtQuick
import QtTest

import "../../services/parsers/AppDrawerUsageParsers.js" as AppDrawerUsageParsers

TestCase {
    name: "AppDrawerUsageParsers"

    function test_normalizeUsageMap() {
        const map = AppDrawerUsageParsers.normalizeUsageMap({
            "firefox.desktop": { launches: 4, lastUsedMs: 12345 },
            "": { launches: 1, lastUsedMs: 1 },
            "bad.desktop": { launches: -5, lastUsedMs: -9 }
        });

        compare(map["firefox.desktop"].launches, 4);
        compare(map["firefox.desktop"].lastUsedMs, 12345);
        verify(!map["bad.desktop"]);
    }

    function test_recordLaunch() {
        const next = AppDrawerUsageParsers.recordLaunch({
            "kitty.desktop": { launches: 2, lastUsedMs: 10 }
        }, "kitty.desktop", 999);

        compare(next["kitty.desktop"].launches, 3);
        compare(next["kitty.desktop"].lastUsedMs, 999);
    }

    function test_buildGioLaunchCommand() {
        const command = AppDrawerUsageParsers.buildGioLaunchCommand("firefox.desktop");
        verify(command.indexOf("gio launch") >= 0);
        verify(command.indexOf("firefox.desktop") >= 0);
        verify(command.indexOf("/usr/share/applications") >= 0);
    }
}
