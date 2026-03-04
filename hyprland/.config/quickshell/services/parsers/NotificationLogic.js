function urgencyKey(value) {
    const raw = (value || "").toString().toLowerCase();
    if (raw.indexOf("critical") >= 0) {
        return "critical";
    }
    if (raw.indexOf("low") >= 0) {
        return "low";
    }
    return "normal";
}

function sanitizeText(value) {
    if (typeof value !== "string") {
        return "";
    }

    return value.replace(/[\r\n]+/g, " ").trim();
}

function shouldRetainInHistory(notification, retainTransient, showReloaded) {
    if (!notification) {
        return false;
    }

    if (!retainTransient && !!notification.transient) {
        return false;
    }

    if (!showReloaded && !!notification.lastGeneration) {
        return false;
    }

    return true;
}

function shouldShowPopup(args) {
    const options = args && typeof args === "object" ? args : ({});
    if (!options.enabled) {
        return false;
    }

    if (!!options.lastGeneration) {
        return false;
    }

    if (!options.dndEnabled) {
        return true;
    }

    if (options.showOnDnd) {
        return true;
    }

    return options.showCriticalOnDnd && urgencyKey(options.urgency) === "critical";
}

function resolveTimeoutMs(args) {
    const options = args && typeof args === "object" ? args : ({});
    const defaultTimeoutMs = Math.max(0, Math.round(options.defaultTimeoutMs || 0));
    const criticalTimeoutMs = Math.max(0, Math.round(options.criticalTimeoutMs || 0));
    const ignoreClient = !!options.ignoreClient;
    const clientSeconds = Number(options.clientSeconds);
    const critical = urgencyKey(options.urgency) === "critical";

    if (!ignoreClient && Number.isFinite(clientSeconds)) {
        if (clientSeconds === 0) {
            return 0;
        }
        if (clientSeconds > 0) {
            return Math.round(clientSeconds * 1000);
        }
    }

    if (critical) {
        return criticalTimeoutMs;
    }

    return defaultTimeoutMs;
}
