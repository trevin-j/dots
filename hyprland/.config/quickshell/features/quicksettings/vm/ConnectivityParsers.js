function stripAnsi(output) {
    if (!output) {
        return "";
    }

    return output
        .replace(/\u001b\[[0-9;?]*[ -/]*[@-~]/g, "")
        .replace(/\r/g, "")
        .trim();
}

function normalizeColonValue(output) {
    const sanitized = stripAnsi(output);
    if (!sanitized) {
        return "";
    }
    return sanitized.includes(":") ? sanitized.split(":").pop().trim() : sanitized.trim();
}

function parseWifiEnabled(output) {
    return normalizeColonValue(output) === "enabled";
}

function parseWifiStats(output) {
    if (!output) {
        return ({ connected: false, strength: -1 });
    }
    const lines = output.split("\n");
    for (const line of lines) {
        if (!line) {
            continue;
        }
        const parts = line.split(":");
        if (parts.length !== 3) {
            continue;
        }
        if (parts[0] !== "*") {
            continue;
        }
        const signalValue = Number(parts[1]);
        if (Number.isNaN(signalValue)) {
            return ({ connected: true, strength: -1 });
        }
        return ({ connected: true, strength: Math.max(0, Math.min(100, signalValue)) });
    }
    return ({ connected: false, strength: -1 });
}

function parseEthernetConnected(output) {
    if (!output) {
        return false;
    }
    const lines = output.split("\n");
    for (const line of lines) {
        if (!line) {
            continue;
        }
        const parts = line.split(":");
        if (parts.length === 2 && parts[0] === "ethernet" && parts[1] === "connected") {
            return true;
        }
    }
    return false;
}

function parseWifiSsid(output, wifiEnabled) {
    if (!wifiEnabled || !output) {
        return "";
    }
    const lines = output.split("\n");
    for (const line of lines) {
        if (!line) {
            continue;
        }
        const parts = line.split(":");
        if (parts.length >= 3 && (parts[1] === "wifi" || parts[1] === "802-11-wireless")) {
            return parts[0];
        }
    }
    return "";
}

function parseBluetoothEnabled(output) {
    const sanitized = stripAnsi(output);
    if (!sanitized) {
        return false;
    }

    if (sanitized === "b true" || sanitized === "true") {
        return true;
    }
    if (sanitized === "b false" || sanitized === "false") {
        return false;
    }

    const lowered = sanitized.toLowerCase();
    if (lowered.includes("powered: yes")) {
        return true;
    }
    if (lowered.includes("powered: no")) {
        return false;
    }

    const value = normalizeColonValue(sanitized).toLowerCase();
    return value.startsWith("enabled");
}

function parseBluetoothDevices(output, bluetoothEnabled) {
    if (!bluetoothEnabled || !output) {
        return "";
    }
    const lines = stripAnsi(output)
        .split("\n")
        .filter(Boolean)
        .map(line => line.replace(/^Device\s+[^\s]+\s+/, "").trim())
        .filter(Boolean);
    return lines.join(", ");
}

function parseAirplaneEnabled(output) {
    return normalizeColonValue(output) === "disabled";
}
