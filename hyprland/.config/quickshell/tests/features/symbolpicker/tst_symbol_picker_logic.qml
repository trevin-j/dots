import QtQuick
import QtTest

import "../../../features/symbolpicker/vm/SymbolPickerLogic.js" as SymbolPickerLogic

TestCase {
    name: "SymbolPickerLogic"

    function test_filterEntriesMatchesHiddenSearchText() {
        const filtered = SymbolPickerLogic.filterEntries([
            { glyph: "😀", label: "grinning face", searchText: "grinning face smile happy" },
            { glyph: "🚀", label: "rocket", searchText: "rocket launch ship" }
        ], "happy grin");

        compare(filtered.length, 1);
        compare(filtered[0].glyph, "😀");
    }

    function test_filterEntriesReturnsAllWhenQueryEmpty() {
        const entries = [
            { glyph: "a", searchText: "alpha" },
            { glyph: "b", searchText: "beta" }
        ];

        compare(SymbolPickerLogic.filterEntries(entries, "").length, 2);
        compare(SymbolPickerLogic.filterEntries(entries, "   ").length, 2);
    }
}
