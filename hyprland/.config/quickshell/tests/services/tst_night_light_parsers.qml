import QtQuick
import QtTest

import "../../services/parsers/NightLightParsers.js" as NightLightParsers

TestCase {
    name: "NightLightParsers"

    function test_clampTemperature() {
        compare(NightLightParsers.clampTemperature(undefined), 3500);
        compare(NightLightParsers.clampTemperature(500), 1000);
        compare(NightLightParsers.clampTemperature(4100), 4100);
        compare(NightLightParsers.clampTemperature(25000), 20000);
    }

    function test_parsePgrepOutput() {
        compare(NightLightParsers.parsePgrepOutput(""), false);
        compare(NightLightParsers.parsePgrepOutput("1234\n"), true);
        compare(NightLightParsers.parsePgrepOutput("1234\n9876\n"), true);
        compare(NightLightParsers.parsePgrepOutput("not-a-pid\n"), false);
    }
}
