import QtQuick

import "../../config" as Config
import "../../design/controls" as Controls
import "../../services" as Services
import "../symbolpicker/vm" as SymbolPickerVm

/*
  EmojiPanelFeature
  Searchable emoji grid picker backed by symbol data and MRU sorting.
  Required properties: panelScreen, state.
 */
Controls.SlideOutGridPanel {
    id: root

    readonly property var gridConfig: Config.Config.emojiPicker && Config.Config.emojiPicker.grid
        ? Config.Config.emojiPicker.grid
        : ({})

    panelNamespace: "quickshell-emoji"
    items: gridModel.filteredEntries
    columns: root.gridConfig.columns || 6
    tileHeight: root.gridConfig.tileHeight || 76
    tileSpacing: root.gridConfig.tileSpacing || 12
    glyphSize: root.gridConfig.glyphSize || 30
    glyphFontFamily: root.gridConfig.fontFamily || ""
    emptyText: Services.SymbolPickerService.isKindLoading("emoji")
        ? "Loading emoji..."
        : (state.query ? "No matching emoji" : "No emoji data loaded")

    SymbolPickerVm.SymbolGridModel {
        id: gridModel

        state: root.state
        presentationOpen: root.presentationOpen
        sourceEntries: Services.SymbolPickerService.emojiEntries
    }

    onActivateRequested: item => {
        root.state.close();
        Services.SymbolPickerService.activateGlyph("emoji", item && item.glyph ? item.glyph : "");
    }
}
