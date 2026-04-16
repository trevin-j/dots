function normalizeMode(rawMode) {
    const mode = typeof rawMode === "string" ? rawMode.toLowerCase().trim() : "";
    if (mode === "username" || mode === "totp") {
        return mode;
    }

    return "password";
}

function tokenizeQuery(rawQuery) {
    const query = typeof rawQuery === "string" ? rawQuery.trim().toLowerCase() : "";
    if (!query) {
        return [];
    }

    return query.split(/\s+/).filter(Boolean);
}

function buildSearchText(entry) {
    const values = [entry.label, entry.username, entry.folder, entry.type, entry.id];
    return values.filter(Boolean).join(" ").toLowerCase();
}

function buildStandardDescription(entry) {
    const parts = [];
    if (entry.username) {
        parts.push(entry.username);
    }
    if (entry.folder) {
        parts.push(entry.folder);
    }
    if (parts.length === 0 && entry.type) {
        parts.push(entry.type);
    }

    return parts.join(" / ");
}

function normalizePeriod(rawPeriod) {
    const value = Math.floor(Number(rawPeriod) || 0);
    return value > 0 ? value : 30;
}

function secondsRemaining(rawPeriod, currentTimeMs) {
    const period = normalizePeriod(rawPeriod);
    const nowMs = Number(currentTimeMs) > 0 ? Number(currentTimeMs) : Date.now();
    const elapsed = Math.floor(nowMs / 1000) % period;
    const remaining = period - elapsed;
    return remaining > 0 ? remaining : period;
}

function buildTotpDescription(entry) {
    return buildStandardDescription(entry);
}

function parseListText(text) {
    const source = typeof text === "string" ? text : "";
    const result = [];
    const lines = source.split(/\r?\n/);
    for (const line of lines) {
        if (!line) {
            continue;
        }

        const parts = line.split("\t");
        const id = parts.length > 0 ? parts[0] : "";
        const label = parts.length > 1 ? parts[1] : "";
        const username = parts.length > 2 ? parts[2] : "";
        const folder = parts.length > 3 ? parts[3] : "";
        const type = parts.length > 4 ? parts[4] : "";
        const entry = {
            id: id,
            label: label || username || id,
            username: username,
            folder: folder,
            type: type,
            icon: "lock",
            period: 30
        };
        entry.searchText = buildSearchText(entry);
        if (entry.id) {
            result.push(entry);
        }
    }

    return result;
}

function parseTotpScanText(text) {
    const source = typeof text === "string" ? text : "";
    const result = ({ });
    for (const rawLine of source.split(/\r?\n/)) {
        const line = rawLine.trim();
        if (!line) {
            continue;
        }

        const parts = line.split("\t");
        const id = parts.length > 0 ? parts[0] : "";
        if (!id) {
            continue;
        }

        result[id] = normalizePeriod(parts.length > 1 ? parts[1] : 30);
    }

    return result;
}

function filterEntries(entries, rawQuery) {
    const source = Array.isArray(entries) ? entries : [];
    const tokens = tokenizeQuery(rawQuery);
    if (tokens.length === 0) {
        return source.slice();
    }

    return source.filter(entry => {
        const haystack = typeof entry.searchText === "string"
            ? entry.searchText
            : buildSearchText(entry);
        for (const token of tokens) {
            if (haystack.indexOf(token) < 0) {
                return false;
            }
        }
        return true;
    });
}

function buildDisplayEntries(entries, rawQuery, rawMode) {
    const mode = normalizeMode(rawMode);
    return filterEntries(entries, rawQuery).map(entry => {
        const next = Object.assign({}, entry);
        if (mode === "totp") {
            next.icon = "pin";
            next.description = buildTotpDescription(next);
        } else if (mode === "username") {
            next.icon = "person";
            next.description = buildStandardDescription(next);
        } else {
            next.icon = "password";
            next.description = buildStandardDescription(next);
        }
        return next;
    });
}
