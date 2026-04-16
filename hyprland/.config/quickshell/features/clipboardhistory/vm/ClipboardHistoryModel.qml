pragma ComponentBehavior: Bound

import QtQuick

import "ClipboardHistoryLogic.js" as ClipboardHistoryLogic
import "./" as ClipboardHistoryVm
import "../../../services" as Services

/*
  ClipboardHistoryModel
  Filters clipboard history entries for list-panel presentation and activation.
  Required properties: state.
 */
QtObject {
    id: root

    required property ClipboardHistoryVm.ClipboardHistoryState state
    required property bool presentationOpen

    readonly property var historyEntries: Services.ClipboardHistoryService.historyEntries ?? []
    readonly property var filteredEntries: root.presentationOpen
        ? ClipboardHistoryLogic.filterEntries(root.historyEntries, root.state.query)
        : []
    readonly property int totalItems: filteredEntries.length
    readonly property var selectedItem: (root.state.selectedIndex >= 0 && root.state.selectedIndex < root.totalItems)
        ? root.filteredEntries[root.state.selectedIndex]
        : null

    function activate(item) {
        if (!item?.rawValue) {
            return;
        }

        Services.ClipboardHistoryService.activateEntry(item.rawValue);
    }

    onFilteredEntriesChanged: root.state.ensureSelectionInRange(root.totalItems)
}
