function iconBaseName(iconName) {
    const raw = iconName ? String(iconName) : "";
    const queryIndex = raw.indexOf("?");
    return queryIndex >= 0 ? raw.slice(0, queryIndex) : raw;
}

function titleFor(item) {
    if (!item) {
        return "";
    }

    return item.tooltipTitle || item.title || item.id || iconBaseName(item.icon) || "";
}

function descriptionFor(item) {
    if (!item) {
        return "";
    }

    return item.tooltipDescription || "";
}

function openMenu(item, menuAnchor, sourceItem, parentWindow, mouseX, mouseY) {
    if (!item || !item.hasMenu) {
        return;
    }

    const localX = Math.round(mouseX !== undefined ? mouseX : sourceItem.width * 0.5);
    const localY = Math.round(mouseY !== undefined ? mouseY : sourceItem.height);

    if (item.display && parentWindow) {
        try {
            const parentContent = parentWindow.contentItem || null;
            const point = sourceItem.mapToItem(parentContent, localX, localY);
            item.display(parentWindow, Math.round(point.x), Math.round(point.y));
            return;
        } catch (_) {
        }
    }

    if (menuAnchor && menuAnchor.menu) {
        menuAnchor.anchor.item = sourceItem;
        menuAnchor.anchor.rect = Qt.rect(localX, localY, 1, 1);
        menuAnchor.open();
    }
}

function activate(item, menuAnchor, sourceItem, parentWindow, mouseX, mouseY) {
    if (!item) {
        return;
    }

    if (item.onlyMenu) {
        openMenu(item, menuAnchor, sourceItem, parentWindow, mouseX, mouseY);
        return;
    }

    if (item.activate) {
        item.activate();
        return;
    }

    if (item.hasMenu) {
        openMenu(item, menuAnchor, sourceItem, parentWindow, mouseX, mouseY);
    }
}

function secondaryActivate(item) {
    if (item && item.secondaryActivate) {
        item.secondaryActivate();
    }
}
