import QtQuick
import QtTest

import "../../services/parsers/RuntimeStateParsers.js" as RuntimeStateParsers

TestCase {
    name: "RuntimeStateParsers"

    function test_parseStateText() {
        const parsed = RuntimeStateParsers.parseStateText('{"wallpaperPath":"/tmp/w.png","darkModeEnabled":true,"notificationsDndEnabled":true}');
        compare(parsed.wallpaperPath, "/tmp/w.png");
        compare(parsed.darkModeEnabled, true);
        compare(parsed.notificationsDndEnabled, true);
    }

    function test_parseStateTextFallback() {
        const parsed = RuntimeStateParsers.parseStateText("not-json");
        compare(parsed.wallpaperPath, "");
        compare(parsed.darkModeEnabled, false);
        compare(parsed.notificationsDndEnabled, false);
    }

    function test_stringifyState() {
        const text = RuntimeStateParsers.stringifyState({
            wallpaperPath: " /tmp/a.jpg ",
            darkModeEnabled: true,
            notificationsDndEnabled: true
        });
        const parsed = JSON.parse(text);
        compare(parsed.wallpaperPath, "/tmp/a.jpg");
        compare(parsed.darkModeEnabled, true);
        compare(parsed.notificationsDndEnabled, true);
    }

    function test_normalizeFileSystemPath_fileScheme() {
        compare(
            RuntimeStateParsers.normalizeFileSystemPath("file:///home/user/.local/state/quickshell/runtime_state.json"),
            "/home/user/.local/state/quickshell/runtime_state.json"
        );
        compare(
            RuntimeStateParsers.normalizeFileSystemPath("file:/home/user/.local/state/quickshell/runtime_state.json"),
            "/home/user/.local/state/quickshell/runtime_state.json"
        );
    }

    function test_normalizeFileSystemPath_plainPath() {
        compare(
            RuntimeStateParsers.normalizeFileSystemPath("/home/user/.local/state/quickshell/runtime_state.json"),
            "/home/user/.local/state/quickshell/runtime_state.json"
        );
    }
}
