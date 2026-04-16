import QtQuick

import "../../config" as Config
import "../../design/controls" as Controls
import "./vm" as ClipboardHistoryVm

/*
  ClipboardHistoryPanelFeature
  Left-edge clipboard history panel backed by the generic searchable list panel.
  Required properties: panelScreen, state.
 */
Controls.SlideOutListPanel {
    id: root

    panelNamespace: "quickshell-clipboardhistory"
    items: historyModel.filteredEntries
    itemHeight: Config.Config.clipboardHistory?.size?.itemHeight ?? 60
    itemSpacing: Config.Config.clipboardHistory?.size?.itemSpacing ?? 8
    itemIconSize: Config.Config.clipboardHistory?.size?.iconSize ?? 18
    emptyText: state.query ? "No matching clipboard items" : "Clipboard history is empty"

    ClipboardHistoryVm.ClipboardHistoryModel {
        id: historyModel

        state: root.state
        presentationOpen: root.presentationOpen
    }

    onActivateRequested: item => {
        historyModel.activate(item);
        root.state.close();
    }
}
