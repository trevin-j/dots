pragma ComponentBehavior: Bound

import QtQuick

/*
  ControlCenterState
  Shared per-screen state for control center visibility and animated edge inset.
*/
QtObject {
    id: root

    property bool open: false
    property int edgeInset: 0

    function toggle() {
        root.open = !root.open;
    }

    function close() {
        root.open = false;
    }

    function openPanel() {
        root.open = true;
    }
}
