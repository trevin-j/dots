import QtQuick

import "../../config" as Config
import "../../design/controls" as Controls
import "../../services" as Services
import "./vm" as BitwardenPickerVm
import "./vm/BitwardenPickerLogic.js" as BitwardenPickerLogic

/*
  BitwardenPanelFeature
  Searchable list panel for Bitwarden passwords, usernames, and TOTP codes.
  Required properties: panelScreen, state.
 */
Controls.SlideOutListPanel {
    id: root

    readonly property var pickerConfig: Config.Config.bitwardenPicker && Config.Config.bitwardenPicker.size
        ? Config.Config.bitwardenPicker.size
        : ({})

    panelNamespace: "quickshell-bitwarden"
    items: pickerModel.filteredEntries
    itemHeight: root.pickerConfig.itemHeight || 64
    itemSpacing: root.pickerConfig.itemSpacing || 8
    itemIconSize: root.pickerConfig.iconSize || 18
    emptyText: Services.BitwardenService.emptyTextForMode(root.state.mode, root.state.query)
    headerStatusText: root.state.mode === "totp"
        ? (BitwardenPickerLogic.secondsRemaining(
            Services.BitwardenService.totpHeaderPeriod,
            Services.BitwardenService.currentTimeMs
        ) + "s")
        : ""

    BitwardenPickerVm.BitwardenPickerModel {
        id: pickerModel

        state: root.state
        presentationOpen: root.presentationOpen
    }

    onActivateRequested: item => {
        pickerModel.activate(item);
        root.state.close();
    }

}
