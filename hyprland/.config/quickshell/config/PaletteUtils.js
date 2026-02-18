function sanitizeMode(value, fallbackMode) {
    if (value === "light" || value === "dark") {
        return value;
    }
    return fallbackMode === "light" ? "light" : "dark";
}

function sanitizeObject(value) {
    return value && typeof value === "object" && !Array.isArray(value) ? value : ({});
}

function sanitizePaletteData(parsedValue, previousMode, previousLight, previousDark) {
    const parsed = sanitizeObject(parsedValue);
    return {
        mode: sanitizeMode(parsed.mode, previousMode),
        light: sanitizeObject(parsed.light || previousLight),
        dark: sanitizeObject(parsed.dark || previousDark)
    };
}
