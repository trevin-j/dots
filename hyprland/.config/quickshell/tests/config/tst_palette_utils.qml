import QtQuick
import QtTest

import "../../config/PaletteUtils.js" as PaletteUtils

TestCase {
    name: "PaletteUtils"

    function test_sanitizeValidPalette() {
        const parsed = {
            mode: "light",
            light: { surface: "#fff" },
            dark: { surface: "#000" }
        };

        const sanitized = PaletteUtils.sanitizePaletteData(parsed, "dark", {}, {});
        compare(sanitized.mode, "light");
        compare(sanitized.light.surface, "#fff");
        compare(sanitized.dark.surface, "#000");
    }

    function test_sanitizeInvalidPaletteUsesFallbacks() {
        const sanitized = PaletteUtils.sanitizePaletteData(null, "dark", { a: 1 }, { b: 2 });
        compare(sanitized.mode, "dark");
        compare(sanitized.light.a, 1);
        compare(sanitized.dark.b, 2);
    }
}
