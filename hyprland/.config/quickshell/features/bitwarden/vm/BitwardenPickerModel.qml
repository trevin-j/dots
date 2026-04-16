pragma ComponentBehavior: Bound

import QtQuick

import "./" as BitwardenPickerVm
import "BitwardenPickerLogic.js" as BitwardenPickerLogic
import "../../../services" as Services

/*
  BitwardenPickerModel
  Filters and decorates Bitwarden picker entries for the shared list panel.
 */
QtObject {
    id: root

    required property BitwardenPickerVm.BitwardenPickerState state
    required property bool presentationOpen

    readonly property var metadataEntries: Services.BitwardenService.metadataEntries ?? []
    readonly property var totpPeriods: Services.BitwardenService.totpPeriods ?? ({})
    readonly property var sourceEntries: {
        const mode = BitwardenPickerLogic.normalizeMode(root.state.mode);
        if (mode === "username") {
            return root.metadataEntries.filter(entry => typeof entry.username === "string" && entry.username !== "");
        }

        if (mode !== "totp") {
            return root.metadataEntries;
        }

        return root.metadataEntries.filter(entry => !!root.totpPeriods[entry.id]).map(entry => {
            const next = Object.assign({}, entry);
            next.period = root.totpPeriods[entry.id] || 30;
            return next;
        });
    }
    readonly property var filteredEntries: root.presentationOpen
        ? BitwardenPickerLogic.buildDisplayEntries(
            root.sourceEntries,
            root.state.query,
            root.state.mode
        )
        : []
    readonly property int totalItems: filteredEntries.length
    readonly property var selectedItem: (root.state.selectedIndex >= 0 && root.state.selectedIndex < root.totalItems)
        ? root.filteredEntries[root.state.selectedIndex]
        : null

    function activate(item) {
        Services.BitwardenService.activateEntry(root.state.mode, item);
    }

    onFilteredEntriesChanged: root.state.ensureSelectionInRange(root.totalItems)
}
