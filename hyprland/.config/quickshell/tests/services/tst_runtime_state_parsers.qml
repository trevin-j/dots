import QtQuick
import QtTest

import "../../services/parsers/RuntimeStateParsers.js" as RuntimeStateParsers

TestCase {
    name: "RuntimeStateParsers"

    function test_parseStateText() {
        const parsed = RuntimeStateParsers.parseStateText('{"wallpaperPath":"/tmp/w.png","darkModeEnabled":true}');
        compare(parsed.wallpaperPath, "/tmp/w.png");
        compare(parsed.darkModeEnabled, true);
    }

    function test_parseStateTextFallback() {
        const parsed = RuntimeStateParsers.parseStateText("not-json");
        compare(parsed.wallpaperPath, "");
        compare(parsed.darkModeEnabled, false);
    }

    function test_stringifyState() {
        const text = RuntimeStateParsers.stringifyState({
            wallpaperPath: " /tmp/a.jpg ",
            darkModeEnabled: true
        });
        const parsed = JSON.parse(text);
        compare(parsed.wallpaperPath, "/tmp/a.jpg");
        compare(parsed.darkModeEnabled, true);
    }
}
