import QtQuick
import QtTest

import "../../services/parsers/SymbolPickerParsers.js" as SymbolPickerParsers

TestCase {
    name: "SymbolPickerParsers"

    function test_normalizeFileSystemPath_fileScheme() {
        compare(
            SymbolPickerParsers.normalizeFileSystemPath("file:///home/user/.local/share/quickshell/symbol-picker/emoji-cache.json"),
            "/home/user/.local/share/quickshell/symbol-picker/emoji-cache.json"
        );
        compare(
            SymbolPickerParsers.normalizeFileSystemPath("file:/home/user/.local/share/quickshell/symbol-picker/nerdfont-cache.json"),
            "/home/user/.local/share/quickshell/symbol-picker/nerdfont-cache.json"
        );
    }

    function test_parseUsageTextCountsRepeatedGlyphs() {
        const counts = SymbolPickerParsers.parseUsageText("😀\n😀\n🚀\n");

        compare(counts["😀"], 2);
        compare(counts["🚀"], 1);
    }

    function test_buildEmojiEntriesFlattensSkinVariantsAndAppliesUsageSort() {
        const entries = SymbolPickerParsers.buildEmojiEntries(JSON.stringify([
            { hexcode: "1F680", label: "rocket", unicode: "🚀" },
            {
                hexcode: "1F44D",
                label: "thumbs up",
                unicode: "👍",
                skins: [
                    { hexcode: "1F44D-1F3FD", label: "thumbs up medium skin tone", unicode: "👍🏽" }
                ]
            }
        ]), {
            "👍🏽": 3,
            "🚀": 1
        });

        compare(entries.length, 3);
        compare(entries[0].glyph, "👍🏽");
        compare(entries[1].glyph, "🚀");
        compare(entries[2].glyph, "👍");
        compare(entries[0].label, "thumbs up medium skin tone");
    }

    function test_buildNerdFontEntriesSkipsMetadataAndUsesNamesForSearch() {
        const entries = SymbolPickerParsers.buildNerdFontEntries(JSON.stringify({
            METADATA: { version: "x" },
            cod_account: { char: "", code: "eb99" },
            md_rocket_launch: { char: "󱓞", code: "f14de" }
        }), {
            "󱓞": 2
        });

        compare(entries.length, 2);
        compare(entries[0].glyph, "󱓞");
        compare(entries[0].id, "md_rocket_launch");
        verify(entries[0].searchText.indexOf("rocket launch") >= 0);
    }
}
