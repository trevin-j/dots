import QtQuick
import QtTest

import "../../services/parsers/BrightnessParsers.js" as BrightnessParsers

TestCase {
    name: "BrightnessParsers"

    function test_clampLevel() {
        compare(BrightnessParsers.clampLevel(-1), 0);
        compare(BrightnessParsers.clampLevel(0.5), 0.5);
        compare(BrightnessParsers.clampLevel(2), 1);
    }

    function test_parseBrightnessctlOutput() {
        const parsed = BrightnessParsers.parseBrightnessctlOutput("intel_backlight,backlight,937,57%\n");
        verify(parsed.ok);
        compare(parsed.deviceName, "intel_backlight");
        compare(parsed.level, 0.57);
    }

    function test_parseBrightnessctlOutputErrors() {
        const empty = BrightnessParsers.parseBrightnessctlOutput("");
        verify(!empty.ok);

        const malformed = BrightnessParsers.parseBrightnessctlOutput("not,enough,parts");
        verify(!malformed.ok);
    }
}
