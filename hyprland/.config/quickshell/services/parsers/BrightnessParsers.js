function clampLevel(value) {
    return Math.max(0, Math.min(1, value));
}

function parseBrightnessctlOutput(output) {
    const trimmed = (output || "").trim();
    if (!trimmed) {
        return ({ ok: false, error: "empty output" });
    }

    const parts = trimmed.split(",");
    if (parts.length < 4) {
        return ({ ok: false, error: "malformed output" });
    }

    const percentValue = Number(parts[3].replace("%", ""));
    if (Number.isNaN(percentValue)) {
        return ({ ok: false, error: "invalid percentage" });
    }

    return ({
        ok: true,
        deviceName: parts[0] || "",
        level: clampLevel(percentValue / 100)
    });
}
