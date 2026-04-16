function normalizeString(value) {
    return typeof value === "string" ? value.trim().toLowerCase() : "";
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
        const haystack = normalizeString(entry?.searchText || entry?.label || "");
        return tokens.every(token => haystack.indexOf(token) >= 0);
    });
}
