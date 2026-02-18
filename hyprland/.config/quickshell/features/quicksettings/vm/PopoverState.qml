pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    property bool trayMenuOpen: false
    property bool closeHold: false

    property bool pillHovered: false
    property bool quickSettingsHovered: false
    property bool trayHovered: false

    property bool trayTooltipVisible: false
    property string trayTooltipTitle: ""
    property string trayTooltipDescription: ""
    property real trayTooltipX: 0
    property real trayTooltipY: 0
    property var trayTooltipSource: null
    property int trayTooltipDelay: 900
    property var trayTooltipPending: null

    readonly property bool popdownOpen: trayMenuOpen || pillHovered || quickSettingsHovered || trayHovered || closeHold

    function showTrayTooltip(entry, titleTextValue, descriptionTextValue, layer, mouseX, mouseY) {
        root.trayTooltipSource = entry;
        root.trayTooltipTitle = titleTextValue || "";
        root.trayTooltipDescription = descriptionTextValue || "";
        updateTrayTooltipPosition(entry, layer, mouseX, mouseY);
        root.trayTooltipVisible = true;
    }

    function updateTrayTooltipPosition(entry, layer, mouseX, mouseY) {
        if (!entry || !layer) {
            return;
        }
        const localX = Math.max(0, Math.round(mouseX ?? entry.width * 0.5));
        const localY = Math.max(0, Math.round(mouseY ?? entry.height));
        const point = entry.mapToItem(layer, localX, localY);
        root.trayTooltipX = Math.round(point.x);
        root.trayTooltipY = Math.round(point.y);
    }

    function scheduleTrayTooltip(entry, mouseX, mouseY, timer) {
        root.trayTooltipPending = entry;
        root.trayTooltipX = mouseX ?? root.trayTooltipX;
        root.trayTooltipY = mouseY ?? root.trayTooltipY;
        if (timer) {
            timer.restart();
        }
    }

    function clearTrayTooltip(entry, timer) {
        if (root.trayTooltipPending === entry) {
            root.trayTooltipPending = null;
        }
        if (root.trayTooltipSource === entry) {
            root.trayTooltipVisible = false;
            root.trayTooltipSource = null;
        }
        if (timer) {
            timer.stop();
        }
    }
}
