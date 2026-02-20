function sanitizeState(input) {
    const raw = input && typeof input === "object" ? input : ({});
    const wallpaperPath = typeof raw.wallpaperPath === "string" ? raw.wallpaperPath.trim() : "";
    const darkModeEnabled = typeof raw.darkModeEnabled === "boolean" ? raw.darkModeEnabled : false;
    return ({
        wallpaperPath: wallpaperPath,
        darkModeEnabled: darkModeEnabled
    });
}

function parseStateText(text) {
    const trimmed = (text || "").trim();
    if (!trimmed) {
        return sanitizeState(({}));
    }

    try {
        return sanitizeState(JSON.parse(trimmed));
    } catch (_error) {
        return sanitizeState(({}));
    }
}

function stringifyState(state) {
    return JSON.stringify(sanitizeState(state));
}
