pragma Singleton

import QtQuick

/*
  PanelExclusivityService
  Coordinates mutually exclusive slide-out panel families across shell services.
 */
QtObject {
    id: root

    property var panels: ({})

    function registerPanel(panelId, controller) {
        if (!panelId || !controller) {
            return;
        }

        const nextPanels = Object.assign({}, root.panels);
        nextPanels[panelId] = controller;
        root.panels = nextPanels;
    }

    function unregisterPanel(panelId, controller) {
        if (!panelId) {
            return;
        }

        if (controller && root.panels[panelId] !== controller) {
            return;
        }

        const nextPanels = Object.assign({}, root.panels);
        delete nextPanels[panelId];
        root.panels = nextPanels;
    }

    function requestOpen(panelId) {
        for (const key of Object.keys(root.panels)) {
            if (key === panelId) {
                continue;
            }

            const controller = root.panels[key];
            if (!controller || typeof controller.closeAll !== "function") {
                continue;
            }

            controller.closeAll();
        }
    }
}
