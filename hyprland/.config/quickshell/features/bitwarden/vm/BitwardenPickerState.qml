pragma ComponentBehavior: Bound

import QtQuick

import "BitwardenPickerLogic.js" as BitwardenPickerLogic

/*
  BitwardenPickerState
  Shared per-screen state for the searchable Bitwarden picker panel.
 */
QtObject {
    id: root

    property bool open: false
    property int edgeInset: 0
    property string query: ""
    property int selectedIndex: -1
    property string mode: "password"

    function resetNavigation() {
        root.selectedIndex = 0;
    }

    function close() {
        root.open = false;
        root.query = "";
        root.resetNavigation();
    }

    function openPanel(rawMode) {
        root.mode = BitwardenPickerLogic.normalizeMode(rawMode);
        root.query = "";
        root.resetNavigation();
        root.open = true;
    }

    function setQuery(value) {
        const next = typeof value === "string" ? value : "";
        if (next === root.query) {
            return;
        }

        root.query = next;
        root.resetNavigation();
    }

    function ensureSelectionInRange(totalItems) {
        const maxIndex = Math.max(-1, totalItems - 1);
        if (maxIndex < 0) {
            root.selectedIndex = -1;
            return;
        }

        if (root.selectedIndex < 0) {
            root.selectedIndex = 0;
        } else if (root.selectedIndex > maxIndex) {
            root.selectedIndex = maxIndex;
        }
    }

    function moveSelection(delta, totalItems, columns) {
        if (totalItems <= 0) {
            root.selectedIndex = -1;
            return;
        }

        const offset = Math.floor(Number(delta) || 0);
        if (!offset && root.selectedIndex >= 0) {
            return;
        }

        root.ensureSelectionInRange(totalItems);
        root.selectedIndex = Math.max(0, Math.min(totalItems - 1, root.selectedIndex + offset));
    }
}
