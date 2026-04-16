import QtQuick
import QtTest

import "../../../features/clipboardhistory/vm/ClipboardHistoryLogic.js" as ClipboardHistoryLogic

TestCase {
    name: "ClipboardHistoryLogic"

    function test_parseListTextParsesIdAndPreview() {
        const parsed = ClipboardHistoryLogic.parseListText("12\tHello world\n34\tAnother clip\n");

        compare(parsed.length, 2);
        compare(parsed[0].id, "12");
        compare(parsed[0].rawValue, "12\tHello world");
        compare(parsed[0].label, "Hello world");
        compare(parsed[0].icon, "content_paste");
        compare(parsed[1].id, "34");
        compare(parsed[1].label, "Another clip");
    }

    function test_parseListTextPreservesTextAfterFirstTab() {
        const parsed = ClipboardHistoryLogic.parseListText("77\tone\ttwo\n");

        compare(parsed.length, 1);
        compare(parsed[0].id, "77");
        compare(parsed[0].label, "one\ttwo");
    }

    function test_parseListTextProvidesEmptyFallbackLabel() {
        const parsed = ClipboardHistoryLogic.parseListText("55\t\n");

        compare(parsed.length, 1);
        compare(parsed[0].label, "(empty)");
    }

    function test_filterEntriesMatchesAllTokens() {
        const filtered = ClipboardHistoryLogic.filterEntries([
            { label: "first clipboard item", description: "" },
            { label: "second note", description: "pasted yesterday" },
            { label: "third thing", description: "clipboard archive" }
        ], "second yesterday");

        compare(filtered.length, 1);
        compare(filtered[0].label, "second note");
    }

    function test_filterEntriesReturnsAllEntriesWhenQueryEmpty() {
        const entries = [
            { label: "alpha", description: "" },
            { label: "beta", description: "" }
        ];

        compare(ClipboardHistoryLogic.filterEntries(entries, "").length, 2);
        compare(ClipboardHistoryLogic.filterEntries(entries, "   ").length, 2);
    }
}
