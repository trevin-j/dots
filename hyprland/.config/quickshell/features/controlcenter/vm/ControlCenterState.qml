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
    property bool wallpaperPickerOpen: false

    function toggle() {
        root.open = !root.open;
        if (!root.open) {
            root.wallpaperPickerOpen = false;
        }
    }

    function close() {
        root.open = false;
        root.wallpaperPickerOpen = false;
    }

    function openPanel() {
        root.open = true;
    }
}
