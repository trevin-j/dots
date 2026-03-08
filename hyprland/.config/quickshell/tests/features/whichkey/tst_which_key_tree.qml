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
                { keys: "<enter>", description: "App drawer", command: "qs ipc call appdrawer toggle" },
                { keys: "Wf", description: "Fullscreen", command: "cmd" },
                { keys: "w-", description: "Invalid", command: "bad" },
                { keys: "wf", description: "Duplicate", command: "dup" }
            ]
        });

        compare(normalized.enabled, true);
        compare(normalized.closeOnUnknown, false);
        compare(normalized.binds.length, 2);
        compare(normalized.binds[0].keys[0], "<enter>");
        compare(normalized.binds[1].keys.join(""), "wf");
    }

    function test_buildTreeAndEntries() {
        const config = WhichKeyTree.normalizeConfig({
            binds: [
                { keys: "<enter>", description: "App drawer", command: "qs ipc call appdrawer toggle" },
                { keys: "w", description: "Window" },
                { keys: "wf", description: "Fullscreen", command: "hyprctl dispatch fullscreen" }
            ]
        });
        const tree = WhichKeyTree.buildTree(config.binds);

        const rootEntries = WhichKeyTree.entriesForPath(tree, []);
        compare(rootEntries.length, 2);
        compare(rootEntries[0].key, "<enter>");
        compare(rootEntries[0].label, "Enter");
        compare(rootEntries[0].command, "qs ipc call appdrawer toggle");
        compare(rootEntries[1].key, "w");
        compare(rootEntries[1].hasChildren, true);

        const windowEntries = WhichKeyTree.entriesForPath(tree, ["w"]);
        compare(windowEntries.length, 1);
        compare(windowEntries[0].key, "f");
        compare(windowEntries[0].command, "hyprctl dispatch fullscreen");
    }
}
