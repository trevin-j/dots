function normalizeRows(value) {
    return Math.max(1, Math.floor(Number(value) || 3));
}

function asList(value) {
    if (!value) {
        return [];
    }

    if (Array.isArray(value)) {
        return value;
    }

    if (typeof value.length === "number") {
        const result = [];
        for (let index = 0; index < value.length; index += 1) {
            result.push(value[index]);
        }
        return result;
    }

    return [];
}

function normalizeColumns(value) {
    return Math.max(1, Math.floor(Number(value) || 10));
}

function normalizeFavorites(value) {
    const source = asList(value);
    const ordered = [];
    const seen = ({});
    for (const item of source) {
        const id = typeof item === "string" ? item.trim() : "";
        if (!id || seen[id]) {
            continue;
        }

        seen[id] = true;
        ordered.push(id);
    }

    return ordered;
}

function normalizePinned(value) {
    return normalizeFavorites(value);
}

function normalizeHidden(value) {
    return normalizeFavorites(value);
}

function normalizeText(value) {
    if (typeof value !== "string") {
        return "";
    }

    return value.trim();
}

function lowercase(value) {
    return normalizeText(value).toLowerCase();
}

function searchTokens(value) {
    const normalized = lowercase(value);
    if (!normalized) {
        return [];
    }

    return normalized.split(/[^a-z0-9]+/).filter(Boolean);
}

function normalizeKeywords(value) {
    const source = asList(value);

    const cleaned = [];
    for (const item of source) {
        const text = normalizeText(item);
        if (text) {
            cleaned.push(text);
        }
    }

    return cleaned.join(" ");
}

function usageRecord(usageMap, desktopId) {
    const source = usageMap && typeof usageMap === "object" ? usageMap : ({});
    const record = source[desktopId];
    if (!record || typeof record !== "object") {
        return {
            launches: 0,
            lastUsedMs: 0
        };
    }

    return {
        launches: Math.max(0, Number(record.launches) || 0),
        lastUsedMs: Math.max(0, Number(record.lastUsedMs) || 0)
    };
}

function frecencyScore(record, nowMs) {
    const launches = Math.max(0, Number(record.launches) || 0);
    const lastUsedMs = Math.max(0, Number(record.lastUsedMs) || 0);
    if (launches <= 0) {
        return 0;
    }

    const now = Math.max(0, Number(nowMs) || Date.now());
    const ageHours = lastUsedMs > 0 ? Math.max(0, (now - lastUsedMs) / 3600000) : 1e9;
    const recencyScore = Math.max(0, 9000 - ageHours * 16);
    return launches * 12000 + recencyScore;
}

function buildCache(entries, favorites, pinnedIds, hiddenIds, usageMap, nowMs) {
    const list = asList(entries);
    const favoriteList = normalizeFavorites(favorites);
    const pinnedList = normalizePinned(pinnedIds);
    const hiddenList = normalizeHidden(hiddenIds);
    const favoriteRankById = ({});
    const pinnedLookup = ({});
    const hiddenLookup = ({});
    for (let i = 0; i < favoriteList.length; i += 1) {
        favoriteRankById[favoriteList[i]] = i;
    }
    for (const id of pinnedList) {
        pinnedLookup[id] = true;
    }
    for (const id of hiddenList) {
        hiddenLookup[id] = true;
    }

    const now = Math.max(0, Number(nowMs) || Date.now());
    const result = [];
    for (const entry of list) {
        if (!entry) {
            continue;
        }

        const desktopId = normalizeText(entry.id);
        if (!desktopId) {
            continue;
        }

        const name = normalizeText(entry.name) || desktopId;
        const genericName = normalizeText(entry.genericName);
        const comment = normalizeText(entry.comment);
        const keywordsText = normalizeKeywords(entry.keywords);
        const searchText = lowercase(`${name} ${genericName} ${keywordsText} ${comment} ${desktopId}`);
        const cachedSearchTokens = searchTokens(searchText);
        const usage = usageRecord(usageMap, desktopId);

        result.push({
            entryRef: entry,
            desktopId: desktopId,
            iconName: normalizeText(entry.icon),
            name: name,
            genericName: genericName,
            comment: comment,
            favoriteRank: Object.prototype.hasOwnProperty.call(favoriteRankById, desktopId)
                ? favoriteRankById[desktopId]
                : -1,
            pinned: !!pinnedLookup[desktopId],
            hidden: !!hiddenLookup[desktopId],
            frecency: frecencyScore(usage, now),
            launches: usage.launches,
            lastUsedMs: usage.lastUsedMs,
            searchText: searchText,
            searchTokens: cachedSearchTokens
        });
    }

    return result;
}

function updateUsageScores(cachedEntries, usageMap, nowMs) {
    const source = asList(cachedEntries);
    const now = Math.max(0, Number(nowMs) || Date.now());
    const refreshed = [];

    for (const item of source) {
        if (!item) {
            continue;
        }

        const usage = usageRecord(usageMap, item.desktopId);
        refreshed.push({
            entryRef: item.entryRef,
            desktopId: item.desktopId,
            iconName: item.iconName,
            name: item.name,
            genericName: item.genericName,
            comment: item.comment,
            favoriteRank: item.favoriteRank,
            pinned: !!item.pinned,
            hidden: !!item.hidden,
            frecency: frecencyScore(usage, now),
            launches: usage.launches,
            lastUsedMs: usage.lastUsedMs,
            searchText: item.searchText,
            searchTokens: asList(item.searchTokens)
        });
    }

    return refreshed;
}

function fuzzyScore(query, haystack, haystackTokens) {
    const needle = normalizeText(query);
    const text = normalizeText(haystack);
    if (!needle) {
        return 1;
    }
    if (!text) {
        return -1;
    }

    const directIndex = text.indexOf(needle);
    if (directIndex >= 0) {
        return 400 - Math.min(240, directIndex * 8) + needle.length * 20;
    }

    const tokens = asList(haystackTokens);
    let bestScore = -1;
    for (const token of tokens) {
        const tokenScore = fuzzyTokenScore(needle, token);
        if (tokenScore > bestScore) {
            bestScore = tokenScore;
        }
    }

    return bestScore;
}

function fuzzyTokenScore(needle, token) {
    if (!needle || !token) {
        return -1;
    }

    const directIndex = token.indexOf(needle);
    if (directIndex >= 0) {
        return 500 - Math.min(200, directIndex * 10) + needle.length * 24;
    }

    let score = 0;
    let prev = -2;
    let textIndex = 0;
    let first = -1;
    let last = -1;
    for (let i = 0; i < needle.length; i += 1) {
        const target = needle[i];
        const found = token.indexOf(target, textIndex);
        if (found < 0) {
            return -1;
        }

        if (first < 0) {
            first = found;
        }
        last = found;

        score += 12;
        if (found === prev + 1) {
            score += 18;
        }
        if (found === 0) {
            score += 8;
        }

        score += Math.max(0, 24 - found);
        prev = found;
        textIndex = found + 1;
    }

    const spread = last - first + 1;
    const extraSpan = spread - needle.length;
    const maxExtraSpan = Math.max(2, Math.floor(needle.length * 1.5));
    if (extraSpan > maxExtraSpan) {
        return -1;
    }

    const density = needle.length / Math.max(1, spread);
    if (density < 0.5) {
        return -1;
    }

    score -= extraSpan * 10;
    score += Math.round(density * 40);

    return score;
}

function compareRankedEntries(a, b) {
    const aPinned = !!a.pinned;
    const bPinned = !!b.pinned;
    if (aPinned !== bPinned) {
        return aPinned ? -1 : 1;
    }

    const aFav = a.favoriteRank >= 0;
    const bFav = b.favoriteRank >= 0;
    if (!aPinned && !bPinned && aFav !== bFav) {
        return aFav ? -1 : 1;
    }
    if (!aPinned && !bPinned && aFav && bFav && a.favoriteRank !== b.favoriteRank) {
        return a.favoriteRank - b.favoriteRank;
    }

    if (a.frecency !== b.frecency) {
        return b.frecency - a.frecency;
    }

    return a.name.localeCompare(b.name);
}

function filterVisibleEntries(cachedEntries, showHidden) {
    if (showHidden) {
        return asList(cachedEntries);
    }

    const source = asList(cachedEntries);
    const result = [];
    for (const item of source) {
        if (!item || item.hidden) {
            continue;
        }

        result.push(item);
    }

    return result;
}

function sortBaseEntries(cachedEntries) {
    const source = asList(cachedEntries);
    const ranked = [];

    for (const item of source) {
        if (item) {
            ranked.push(item);
        }
    }

    ranked.sort(compareRankedEntries);
    return ranked;
}

function rankAndFilter(cachedEntries, query) {
    const source = asList(cachedEntries);
    const normalizedQuery = normalizeText(query);
    if (!normalizedQuery) {
        return sortBaseEntries(source);
    }

    const filtered = [];

    for (const item of source) {
        if (!item) {
            continue;
        }

        const fuzzy = fuzzyScore(normalizedQuery, item.searchText, item.searchTokens);
        if (fuzzy < 0) {
            continue;
        }

        filtered.push({
            entryRef: item.entryRef,
            desktopId: item.desktopId,
            iconName: item.iconName,
            name: item.name,
            genericName: item.genericName,
            favoriteRank: item.favoriteRank,
            pinned: !!item.pinned,
            hidden: !!item.hidden,
            frecency: item.frecency,
            searchText: item.searchText,
            searchTokens: asList(item.searchTokens),
            fuzzyScore: fuzzy
        });
    }

    filtered.sort((a, b) => {
        const rankedOrder = compareRankedEntries(a, b);
        if (rankedOrder !== 0) {
            return rankedOrder;
        }
        if (a.fuzzyScore !== b.fuzzyScore) {
            return b.fuzzyScore - a.fuzzyScore;
        }

        return 0;
    });

    return filtered;
}
