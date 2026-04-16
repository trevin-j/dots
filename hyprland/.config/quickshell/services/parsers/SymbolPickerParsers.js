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

function normalizeUsageCounts(value) {
    const source = value && typeof value === "object" ? value : ({});
    const result = ({});
    for (const key of Object.keys(source)) {
        const normalizedKey = typeof key === "string" ? key : "";
        const count = Math.max(0, Math.floor(Number(source[key]) || 0));
        if (!normalizedKey || count <= 0) {
            continue;
        }

        result[normalizedKey] = count;
    }

    return result;
}

function parseUsageText(text) {
    const result = ({});
    const normalized = typeof text === "string" ? text : "";
    for (const line of normalized.split(/\r?\n/)) {
        if (!line) {
            continue;
        }

        result[line] = (result[line] || 0) + 1;
    }

    return normalizeUsageCounts(result);
}

function recordUsage(usageCounts, glyph) {
    const next = normalizeUsageCounts(usageCounts);
    const key = typeof glyph === "string" ? glyph : "";
    if (!key) {
        return next;
    }

    next[key] = (next[key] || 0) + 1;
    return next;
}

function normalizeSearchText(parts) {
    const values = [];
    const source = Array.isArray(parts) ? parts : [];
    for (const part of source) {
        if (typeof part !== "string") {
            continue;
        }

        const trimmed = part.trim();
        if (!trimmed) {
            continue;
        }

        values.push(trimmed.replace(/[_-]+/g, " "));
        values.push(trimmed);
    }

    return values.join(" ").trim();
}

function sortEntries(entries, usageCounts) {
    const source = Array.isArray(entries) ? entries.slice() : [];
    const usage = normalizeUsageCounts(usageCounts);
    return source.sort((left, right) => {
        const leftCount = usage[left.glyph] || 0;
        const rightCount = usage[right.glyph] || 0;
        if (leftCount !== rightCount) {
            return rightCount - leftCount;
        }

        return (left.sourceIndex || 0) - (right.sourceIndex || 0);
    });
}

function buildEmojiEntries(text, usageCounts) {
    let parsed = [];
    try {
        parsed = text ? JSON.parse(text) : [];
    } catch (_error) {
        parsed = [];
    }

    if (!Array.isArray(parsed)) {
        return [];
    }

    const entries = [];
    let sourceIndex = 0;

    function pushEntry(item, fallbackLabel) {
        const glyph = typeof item?.unicode === "string" ? item.unicode : "";
        if (!glyph) {
            return;
        }

        const label = typeof item?.label === "string" && item.label.trim()
            ? item.label.trim()
            : fallbackLabel;
        const id = typeof item?.hexcode === "string" && item.hexcode.trim()
            ? item.hexcode.trim()
            : `${glyph}-${sourceIndex}`;

        entries.push({
            id: id,
            glyph: glyph,
            label: label,
            searchText: normalizeSearchText([label, id]),
            sourceIndex: sourceIndex
        });
        sourceIndex += 1;
    }

    for (const item of parsed) {
        const fallbackLabel = typeof item?.label === "string" ? item.label.trim() : "";
        pushEntry(item, fallbackLabel);
        const skins = Array.isArray(item?.skins) ? item.skins : [];
        for (const skin of skins) {
            pushEntry(skin, fallbackLabel);
        }
    }

    return sortEntries(entries, usageCounts);
}

function buildNerdFontEntries(text, usageCounts) {
    let parsed = ({});
    try {
        parsed = text ? JSON.parse(text) : ({});
    } catch (_error) {
        parsed = ({});
    }

    if (!parsed || typeof parsed !== "object") {
        return [];
    }

    const entries = [];
    let sourceIndex = 0;
    for (const key of Object.keys(parsed)) {
        if (key === "METADATA") {
            continue;
        }

        const item = parsed[key];
        const glyph = typeof item?.char === "string" ? item.char : "";
        if (!glyph) {
            continue;
        }

        entries.push({
            id: key,
            glyph: glyph,
            label: key,
            searchText: normalizeSearchText([key, item?.code || ""]),
            sourceIndex: sourceIndex
        });
        sourceIndex += 1;
    }

    return sortEntries(entries, usageCounts);
}
