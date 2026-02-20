import QtQuick
import QtTest

import "../../../features/whichkey/vm/WhichKeyTree.js" as WhichKeyTree

TestCase {
    name: "WhichKeyTree"

    function test_normalizeConfig() {
        const normalized = WhichKeyTree.normalizeConfig({
            enabled: true,
            closeOnUnknown: false,
            title: "Leader",
            binds: [
                { keys: "Wf", description: "Fullscreen", command: "cmd" },
                { keys: "w-", description: "Invalid", command: "bad" },
                { keys: "wf", description: "Duplicate", command: "dup" }
            ]
        });

        compare(normalized.enabled, true);
        compare(normalized.closeOnUnknown, false);
        compare(normalized.binds.length, 1);
        compare(normalized.binds[0].keys, "wf");
    }

    function test_buildTreeAndEntries() {
        const config = WhichKeyTree.normalizeConfig({
            binds: [
                { keys: "w", description: "Window" },
                { keys: "wf", description: "Fullscreen", command: "hyprctl dispatch fullscreen" }
            ]
        });
        const tree = WhichKeyTree.buildTree(config.binds);

        const rootEntries = WhichKeyTree.entriesForPath(tree, []);
        compare(rootEntries.length, 1);
        compare(rootEntries[0].key, "w");
        compare(rootEntries[0].hasChildren, true);

        const windowEntries = WhichKeyTree.entriesForPath(tree, ["w"]);
        compare(windowEntries.length, 1);
        compare(windowEntries[0].key, "f");
        compare(windowEntries[0].command, "hyprctl dispatch fullscreen");
    }
}
