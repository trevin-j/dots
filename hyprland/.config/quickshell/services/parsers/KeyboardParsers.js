function layerNamespaceVisible(input, namespace) {
    const target = typeof namespace === "string" ? namespace.trim() : "";
    if (!target) {
        return false;
    }

    function visit(node) {
        if (!node) {
            return false;
        }

        if (Array.isArray(node)) {
            for (const entry of node) {
                if (visit(entry)) {
                    return true;
                }
            }
            return false;
        }

        if (typeof node !== "object") {
            return false;
        }

        if (node.namespace === target) {
            return true;
        }

        for (const key of Object.keys(node)) {
            if (visit(node[key])) {
                return true;
            }
        }

        return false;
    }

    return visit(input);
}

function parseLayerState(text, namespace) {
    const trimmed = (text || "").trim();
    if (!trimmed) {
        return false;
    }

    try {
        return layerNamespaceVisible(JSON.parse(trimmed), namespace);
    } catch (_error) {
        return false;
    }
}
