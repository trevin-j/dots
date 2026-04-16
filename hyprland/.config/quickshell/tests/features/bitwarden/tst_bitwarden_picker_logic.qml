import QtQuick
import QtTest

import "../../../features/bitwarden/vm/BitwardenPickerLogic.js" as BitwardenPickerLogic

TestCase {
    name: "BitwardenPickerLogic"

    function test_parseListTextParsesTabbedMetadata() {
        const entries = BitwardenPickerLogic.parseListText(
            "id-1\tGithub\tdev\tWork\tlogin\n"
            + "id-2\tNotes\t\t\tnote\n"
        );

        compare(entries.length, 2);
        compare(entries[0].id, "id-1");
        compare(entries[0].label, "Github");
        compare(entries[0].username, "dev");
        compare(entries[0].folder, "Work");
        compare(entries[1].type, "note");
    }

    function test_filterEntriesMatchesNameUsernameAndFolder() {
        const filtered = BitwardenPickerLogic.filterEntries([
            { id: "1", label: "Github", username: "trev", folder: "Work", searchText: "github trev work login" },
            { id: "2", label: "Bank", username: "me", folder: "Finance", searchText: "bank me finance login" }
        ], "trev work");

        compare(filtered.length, 1);
        compare(filtered[0].id, "1");
    }

    function test_parseTotpScanTextBuildsPeriodMap() {
        const periods = BitwardenPickerLogic.parseTotpScanText("id-1\t30\nid-2\t60\n");

        compare(periods["id-1"], 30);
        compare(periods["id-2"], 60);
    }

    function test_secondsRemainingWrapsAtPeriodBoundary() {
        compare(BitwardenPickerLogic.secondsRemaining(30, 29000), 1);
        compare(BitwardenPickerLogic.secondsRemaining(30, 30000), 30);
    }
}
