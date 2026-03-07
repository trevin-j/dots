const BUILTIN_FILENAMES = {
    bouncy: "bouncy.wav",
    warm: "warm.wav",
    chime: "chime.wav"
};

const DEFAULT_BUILTIN = "warm";
const DISABLED_CHOICES = {
    off: true,
    none: true,
    disabled: true
};
const DELTA_THRESHOLD = 0.0005;

function normalizeSoundChoice(value) {
    if (typeof value !== "string") {
        return "";
    }

    return value.trim();
}

function normalizeSuppressWhenMicActive(value) {
    if (value === undefined || value === null) {
        return true;
    }

    return !!value;
}

function shellQuote(value) {
    const text = String(value || "");
    const escaped = text.replace(/(["\\$`])/g, "\\$1");
    return `"${escaped}"`;
}

function defaultBuiltinBasePath(homeDir) {
    return (homeDir || "") + "/.config/quickshell/assets/sounds/volume/";
}

function urlToLocalPath(value) {
    const text = typeof value === "string" ? value : "";
    if (!text.startsWith("file://")) {
        return text;
    }

    const trimmed = text.slice("file://".length);
    if (!trimmed) {
        return "";
    }

    return decodeURIComponent(trimmed.startsWith("/") ? trimmed : `/${trimmed}`);
}

function builtinPath(builtinBasePath, homeDir, name) {
    const base = (builtinBasePath && builtinBasePath.trim()) || defaultBuiltinBasePath(homeDir);
    return base + BUILTIN_FILENAMES[name];
}

function expandHome(path, homeDir) {
    if (typeof path !== "string") {
        return "";
    }

    if (path.startsWith("~/")) {
        return (homeDir || "") + path.slice(1);
    }

    return path;
}

function resolveSoundPath(configValue, builtinBasePath, homeDir) {
    const normalized = normalizeSoundChoice(configValue);
    if (!normalized) {
        return builtinPath(builtinBasePath, homeDir, DEFAULT_BUILTIN);
    }

    if (Object.prototype.hasOwnProperty.call(DISABLED_CHOICES, normalized)) {
        return "";
    }

    if (Object.prototype.hasOwnProperty.call(BUILTIN_FILENAMES, normalized)) {
        return builtinPath(builtinBasePath, homeDir, normalized);
    }

    const expanded = expandHome(normalized, homeDir);
    if (expanded.startsWith("/")) {
        return expanded;
    }

    return builtinPath(builtinBasePath, homeDir, DEFAULT_BUILTIN);
}

function directionForDelta(delta) {
    const amount = Number(delta);
    if (Number.isNaN(amount) || Math.abs(amount) < DELTA_THRESHOLD) {
        return "";
    }

    return amount > 0 ? "up" : "down";
}

function buildPlayCommand(path, suppressWhenMicActive) {
    const quotedPath = shellQuote(path);
    const shouldSuppress = normalizeSuppressWhenMicActive(suppressWhenMicActive);
    const suppressGuard = shouldSuppress
        ? "if command -v pactl >/dev/null 2>&1 && [ -n \"$(pactl list source-outputs short 2>/dev/null)\" ]; then exit 0; fi; "
        : "";
    return `${suppressGuard}(pw-play ${quotedPath} || paplay ${quotedPath}) >/dev/null 2>&1 &`;
}
