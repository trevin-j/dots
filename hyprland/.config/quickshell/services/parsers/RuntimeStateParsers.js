function sanitizeState(input) {
    const raw = input && typeof input === "object" ? input : ({});
    const wallpaperPath = typeof raw.wallpaperPath === "string" ? raw.wallpaperPath.trim() : "";
    const darkModeEnabled = typeof raw.darkModeEnabled === "boolean" ? raw.darkModeEnabled : false;
    const notificationsDndEnabled = typeof raw.notificationsDndEnabled === "boolean"
        ? raw.notificationsDndEnabled
        : false;
    return ({
        wallpaperPath: wallpaperPath,
        darkModeEnabled: darkModeEnabled,
        notificationsDndEnabled: notificationsDndEnabled
    });
}

function normalizeFileSystemPath(value) {
    if (typeof value !== "string") {
        return "";
    }

    const trimmed = value.trim();
    if (!trimmed) {
        return "";
    }

    let normalized = trimmed;
    if (normalized.startsWith("file://")) {
        normalized = normalized.slice("file://".length);
    } else if (normalized.startsWith("file:/")) {
        normalized = normalized.slice("file:".length);
    }

    try {
        return decodeURIComponent(normalized);
    } catch (_error) {
        return normalized;
    }
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
