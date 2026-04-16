function normalizeString(value) {
    return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function parseListText(text) {
    if (typeof text !== "string" || text === "") {
        return [];
    }

    const result = [];
    const lines = text.split(/\r?\n/);
    for (const line of lines) {
        if (!line) {
            continue;
        }

        const tabIndex = line.indexOf("\t");
        const id = tabIndex >= 0 ? line.slice(0, tabIndex) : line;
        const preview = tabIndex >= 0 ? line.slice(tabIndex + 1) : line;
        const label = preview === "" ? "(empty)" : preview;

        result.push({
            id: id,
            rawValue: line,
            label: label,
            description: "",
            icon: "content_paste"
        });
    }

    return result;
}

function filterEntries(entries, query) {
    const source = Array.isArray(entries) ? entries : [];
    const normalizedQuery = normalizeString(query);
    if (!normalizedQuery) {
        return source;
    }

    const tokens = normalizedQuery.split(/\s+/).filter(Boolean);
    if (tokens.length === 0) {
        return source;
    }

    return source.filter(entry => {
        const haystack = normalizeString(`${entry?.label || ""} ${entry?.description || ""}`);
        return tokens.every(token => haystack.indexOf(token) >= 0);
    });
}
