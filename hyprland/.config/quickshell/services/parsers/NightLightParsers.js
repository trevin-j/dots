function clampTemperature(value) {
    if (value === undefined || value === null || Number.isNaN(value)) {
        return 3500;
    }

    return Math.max(1000, Math.min(20000, Math.round(value)));
}

function parsePgrepOutput(output) {
    const text = (output || "").trim();
    if (!text) {
        return false;
    }

    const lines = text.split(/\r?\n/);
    return lines.some(line => /^\d+$/.test(line.trim()));
}
