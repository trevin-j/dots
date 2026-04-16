pragma ComponentBehavior: Bound

import QtQuick

import "SymbolPickerLogic.js" as SymbolPickerLogic
import "./" as SymbolPickerVm

/*
  SymbolGridModel
  Filters searchable symbol entries for grid-panel presentation.
  Required properties: state, sourceEntries.
 */
QtObject {
    id: root

    required property SymbolPickerVm.SymbolPickerState state
    required property bool presentationOpen
    required property var sourceEntries

    readonly property var filteredEntries: root.presentationOpen
        ? SymbolPickerLogic.filterEntries(root.sourceEntries, root.state.query)
        : []
    readonly property int totalItems: filteredEntries.length
    readonly property var selectedItem: (root.state.selectedIndex >= 0 && root.state.selectedIndex < root.totalItems)
        ? root.filteredEntries[root.state.selectedIndex]
        : null

    onFilteredEntriesChanged: root.state.ensureSelectionInRange(root.totalItems)
}
