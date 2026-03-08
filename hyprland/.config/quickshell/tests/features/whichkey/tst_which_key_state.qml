import QtQuick
import QtTest

import "../../../features/whichkey/vm" as WhichKeyVm

TestCase {
    name: "WhichKeyState"

    WhichKeyVm.WhichKeyState {
        id: state

        config: ({
            enabled: true,
            closeOnUnknown: true,
            binds: [
                { keys: "<enter>", description: "App drawer", command: "qs ipc call appdrawer toggle" },
                { keys: "w", description: "Window" },
                { keys: "wf", description: "Fullscreen", command: "hyprctl dispatch fullscreen" }
            ]
        })
    }

    property string lastCommand: ""

    Connections {
        target: state

        function onCommandRequested(command) {
            lastCommand = command;
        }
    }

    function init() {
        lastCommand = "";
        state.close();
        state.applyConfig(state.config);
    }

    function test_toggleAndBack() {
        compare(state.open, false);
        state.toggleLeader();
        compare(state.open, true);

        state.activateEntry("w");
        compare(state.path.length, 1);
        compare(state.path[0], "w");

        state.back();
        compare(state.path.length, 0);
        compare(state.open, true);

        state.back();
        compare(state.open, false);
    }

    function test_executeLeafCommand() {
        state.openLeader();
        state.activateEntry("w");
        state.activateEntry("f");

        compare(state.open, false);
        compare(lastCommand, "hyprctl dispatch fullscreen");
    }

    function test_unknownKeyClosesWhenConfigured() {
        state.openLeader();
        state.activateEntry("x");
        compare(state.open, false);
    }

    function test_enterBindAtLeaderRoot() {
        state.openLeader();
        state.activateEntry("<enter>");

        compare(state.open, false);
        compare(lastCommand, "qs ipc call appdrawer toggle");
    }
}
