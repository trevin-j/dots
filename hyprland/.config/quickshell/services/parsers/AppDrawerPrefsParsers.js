function normalizeDesktopId(value) {
    if (typeof value !== "string") {
        return "";
    }

    return value.trim();
}

function normalizeDesktopIdList(value) {
    const source = Array.isArray(value) ? value : [];
    const result = [];
    const seen = ({});
    for (const item of source) {
        const id = normalizeDesktopId(item);
        if (!id || seen[id]) {
            continue;
        }

        seen[id] = true;
        result.push(id);
    }

    return result;
}

function normalizePrefs(value) {
    const source = value && typeof value === "object" ? value : ({});
    const hiddenLookup = ({});
    const hiddenIds = normalizeDesktopIdList(source.hiddenIds);
    for (const id of hiddenIds) {
        hiddenLookup[id] = true;
    }

    const pinnedIds = normalizeDesktopIdList(source.pinnedIds).filter(id => !hiddenLookup[id]);
    return {
        pinnedIds: pinnedIds,
        hiddenIds: hiddenIds,
        showHidden: !!source.showHidden
    };
}

function parsePrefsText(text) {
    try {
        const parsed = text ? JSON.parse(text) : ({});
        return normalizePrefs(parsed);
    } catch (_) {
        return normalizePrefs({});
    }
}

function stringifyPrefs(value) {
    return JSON.stringify(normalizePrefs(value));
}

function setPinned(prefs, desktopId, pinned) {
    const next = normalizePrefs(prefs);
    const id = normalizeDesktopId(desktopId);
    if (!id) {
        return next;
    }

    next.pinnedIds = next.pinnedIds.filter(entry => entry !== id);
    if (pinned && next.hiddenIds.indexOf(id) < 0) {
        next.pinnedIds.push(id);
    }

    return normalizePrefs(next);
}

function setHidden(prefs, desktopId, hidden) {
    const next = normalizePrefs(prefs);
    const id = normalizeDesktopId(desktopId);
    if (!id) {
        return next;
    }

    next.hiddenIds = next.hiddenIds.filter(entry => entry !== id);
    if (hidden) {
        next.hiddenIds.push(id);
    }

    if (hidden) {
        next.pinnedIds = next.pinnedIds.filter(entry => entry !== id);
    }

    return normalizePrefs(next);
}

function setShowHidden(prefs, showHidden) {
    const next = normalizePrefs(prefs);
    next.showHidden = !!showHidden;
    return next;
}
