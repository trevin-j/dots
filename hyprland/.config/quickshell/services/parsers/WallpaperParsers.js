function normalizeExtensions(rawExtensions) {
    if (!Array.isArray(rawExtensions) || rawExtensions.length === 0) {
        return [".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"];
    }

    const normalized = [];
    for (const value of rawExtensions) {
        if (typeof value !== "string") {
            continue;
        }
        const trimmed = value.trim().toLowerCase();
        if (!trimmed) {
            continue;
        }
        normalized.push(trimmed.startsWith(".") ? trimmed : `.${trimmed}`);
    }

    return normalized.length > 0 ? normalized : [".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"];
}

function parseDiscoveryOutput(text) {
    const trimmed = (text || "").trim();
    if (!trimmed) {
        return [];
    }

    try {
        const parsed = JSON.parse(trimmed);
        if (!Array.isArray(parsed)) {
            return [];
        }
        return parsed.filter(item => typeof item === "string" && item.trim() !== "");
    } catch (_error) {
        return [];
    }
}

function compareImagePaths(left, right) {
    const leftName = String(left || "").split("/").pop().toLowerCase();
    const rightName = String(right || "").split("/").pop().toLowerCase();
    if (leftName < rightName) {
        return -1;
    }
    if (leftName > rightName) {
        return 1;
    }
    const leftPath = String(left || "").toLowerCase();
    const rightPath = String(right || "").toLowerCase();
    if (leftPath < rightPath) {
        return -1;
    }
    if (leftPath > rightPath) {
        return 1;
    }
    return 0;
}

function sortedImagePaths(paths) {
    const safePaths = Array.isArray(paths) ? paths.slice() : [];
    safePaths.sort(compareImagePaths);
    return safePaths;
}

function indexForPath(paths, candidatePath) {
    if (!Array.isArray(paths) || paths.length === 0) {
        return -1;
    }
    if (typeof candidatePath !== "string" || candidatePath.trim() === "") {
        return -1;
    }
    return paths.indexOf(candidatePath);
}

function clampIndex(index, count) {
    if (!Number.isFinite(index) || count <= 0) {
        return -1;
    }
    return Math.max(0, Math.min(count - 1, Math.round(index)));
}

function buildMatugenArgs(wallpaperPath, darkModeEnabled) {
    const mode = darkModeEnabled ? "dark" : "light";
    return [
        "matugen",
        "image",
        "-t",
        "scheme-vibrant",
        "-m",
        mode,
        wallpaperPath,
        "--source-color-index",
        "0"
    ];
}
