import QtQuick
import QtTest

import "../../../features/controlcenter/vm" as ControlCenterVm

TestCase {
    name: "ControlCenterState"

    ControlCenterVm.ControlCenterState {
        id: state
    }

    function init() {
        state.open = false;
        state.edgeInset = 0;
    }

    function test_toggle() {
        compare(state.open, false);
        state.toggle();
        compare(state.open, true);
        state.toggle();
        compare(state.open, false);
    }

    function test_openCloseHelpers() {
        state.openPanel();
        compare(state.open, true);
        state.close();
        compare(state.open, false);
    }
}
