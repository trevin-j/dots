function normalizeDesktopId(value) {
    if (typeof value !== "string") {
        return "";
    }

    const trimmed = value.trim();
    return trimmed;
}

function normalizeUsageRecord(value) {
    const source = value && typeof value === "object" ? value : ({});
    const launches = Math.max(0, Number(source.launches) || 0);
    const lastUsedMs = Math.max(0, Number(source.lastUsedMs) || 0);

    return {
        launches: launches,
        lastUsedMs: lastUsedMs
    };
}

function normalizeUsageMap(value) {
    const source = value && typeof value === "object" ? value : ({});
    const result = ({});
    const keys = Object.keys(source);
    for (const key of keys) {
        const id = normalizeDesktopId(key);
        if (!id) {
            continue;
        }

        const normalized = normalizeUsageRecord(source[key]);
        if (normalized.launches <= 0 && normalized.lastUsedMs <= 0) {
            continue;
        }

        result[id] = normalized;
    }

    return result;
}

function parseUsageText(text) {
    try {
        const parsed = text ? JSON.parse(text) : ({});
        return normalizeUsageMap(parsed);
    } catch (error) {
        return ({});
    }
}

function stringifyUsageMap(value) {
    return JSON.stringify(normalizeUsageMap(value));
}

function recordLaunch(usageMap, desktopId, timestampMs) {
    const next = normalizeUsageMap(usageMap);
    const id = normalizeDesktopId(desktopId);
    if (!id) {
        return next;
    }

    const nowMs = Math.max(0, Number(timestampMs) || Date.now());
    const previous = next[id] || {
        launches: 0,
        lastUsedMs: 0
    };

    next[id] = {
        launches: previous.launches + 1,
        lastUsedMs: nowMs
    };
    return next;
}

function usageScore(record, nowMs) {
    const normalized = normalizeUsageRecord(record);
    if (normalized.launches <= 0) {
        return 0;
    }

    const now = Math.max(0, Number(nowMs) || Date.now());
    const ageHours = normalized.lastUsedMs > 0 ? Math.max(0, (now - normalized.lastUsedMs) / 3600000) : 1e9;
    const recencyScore = Math.max(0, 9000 - ageHours * 16);
    return normalized.launches * 12000 + recencyScore;
}

function normalizeFileSystemPath(value) {
    if (typeof value !== "string") {
        return "";
    }

    if (value.startsWith("file://")) {
        const trimmed = value.slice("file://".length);
        return decodeURIComponent(trimmed.startsWith("/") ? trimmed : `/${trimmed}`);
    }

    return value;
}

function shellQuote(value) {
    const text = String(value || "");
    const escaped = text.replace(/(["\\$`])/g, "\\$1");
    return `"${escaped}"`;
}

function buildGioLaunchCommand(desktopId) {
    const id = normalizeDesktopId(desktopId);
    if (!id) {
        return "exit 1";
    }

    const quotedId = shellQuote(id);
    const baseDirs = [
        "$HOME/.local/share/applications",
        "$HOME/.local/share/flatpak/exports/share/applications",
        "/var/lib/flatpak/exports/share/applications",
        "/usr/local/share/applications",
        "/usr/share/applications"
    ];
    const quotedDirs = baseDirs.map(dir => shellQuote(dir)).join(" ");
    return `id=${quotedId}; if [ -f \"$id\" ]; then gio launch \"$id\"; exit $?; fi; for dir in ${quotedDirs}; do eval expanded=\"$dir\"; if [ -f \"$expanded/$id\" ]; then gio launch \"$expanded/$id\"; exit $?; fi; done; exit 1`;
}
