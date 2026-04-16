function defaultBinds() {
    return [
        { keys: "<enter>", description: "App drawer", command: "qs ipc call appdrawer toggle", icon: "apps" },
        { keys: "p", description: "Power", command: "tlgui power", icon: "power_settings_new" },
        { keys: "w", description: "Window", icon: "web_asset" },
        { keys: "wf", description: "Fullscreen", command: "hyprctl dispatch fullscreen", icon: "fullscreen" },
        { keys: "wh", description: "Toggle floating", command: "hyprctl dispatch togglefloating", icon: "picture_in_picture_alt" },
        { keys: "wp", description: "Toggle pseudo", command: "hyprctl dispatch pseudo", icon: "splitscreen" },
        { keys: "wd", description: "Discord special workspace", command: "hyprctl dispatch togglespecialworkspace discord", icon: "forum" },
        { keys: "wo", description: "OBS special workspace", command: "hyprctl dispatch togglespecialworkspace obsstudio", icon: "videocam" },
        { keys: "l", description: "Layout", icon: "dashboard" },
        { keys: "ls", description: "Toggle split", command: "hyprctl dispatch togglesplit", icon: "call_split" },
        { keys: "lr", description: "Move to root", command: "hyprctl dispatch layoutmsg movetoroot", icon: "account_tree" },
        { keys: "lp", description: "Swap split", command: "hyprctl dispatch layoutmsg swapsplit", icon: "swap_horiz" },
        { keys: "li", description: "Pin window", command: "hyprctl dispatch pin", icon: "push_pin" },
        { keys: "u", description: "Utilities", icon: "build" },
        { keys: "ud", description: "Dictation", icon: "keyboard_voice" },
        { keys: "uds", description: "Start dictation", command: "nerd-dictation begin --simulate-input-tool=WTYPE", icon: "keyboard_voice" },
        { keys: "ude", description: "End dictation", command: "nerd-dictation end", icon: "mic_off" },
        { keys: "uw", description: "Wallpaper", icon: "wallpaper" },
        { keys: "uws", description: "Skip wallpaper", command: "sh ~/.config/hypr/wallcycle.sh skip", icon: "wallpaper" },
        { keys: "uwr", description: "Remove wallpaper", command: "sh ~/.config/hypr/wallcycle.sh skip --rm", icon: "delete" },
        { keys: "uc", description: "Color picker", command: "hyprpicker | wl-copy -n", icon: "colorize" },
        { keys: "un", description: "Notifications", command: "qs ipc call controlcenter toggle", icon: "notifications" },
        { keys: "s", description: "Search", icon: "search" },
        { keys: "sp", description: "Passwords", command: "qs ipc call bitwarden togglePassword", icon: "password" },
        { keys: "st", description: "TOTP codes", command: "qs ipc call bitwarden toggleTotp", icon: "pin" },
        { keys: "su", description: "Usernames", command: "qs ipc call bitwarden toggleUsername", icon: "person" },
        { keys: "sc", description: "Clipboard history", command: "qs ipc call clipboardhistory toggle", icon: "content_paste" },
        { keys: "se", description: "Emoji picker", command: "qs ipc call emoji toggle", icon: "emoji_emotions" },
        { keys: "sn", description: "Nerd font picker", command: "qs ipc call nerdfont toggle", icon: "font_download" }
    ];
}

function emptyTree() {
    return ({
        description: "",
        command: "",
        icon: "",
        children: ({})
    });
}

function keyTokenLabel(token) {
    if (token === "<enter>") {
        return "keyboard_return";
    }

    return typeof token === "string" ? token.toUpperCase() : "";
}

function parseKeySequence(value) {
    if (typeof value !== "string") {
        return [];
    }

    const normalized = value.trim().toLowerCase();
    if (!normalized) {
        return [];
    }

    const tokens = [];
    let index = 0;
    while (index < normalized.length) {
        const current = normalized[index];
        if (current === "<") {
            const end = normalized.indexOf(">", index);
            if (end < 0) {
                return [];
            }

            const token = normalized.slice(index, end + 1);
            if (token !== "<enter>") {
                return [];
            }

            tokens.push(token);
            index = end + 1;
            continue;
        }

        if (!/[a-z0-9]/.test(current)) {
            return [];
        }

        tokens.push(current);
        index += 1;
    }

    return tokens;
}

function normalizeBinds(rawBinds) {
    const source = Array.isArray(rawBinds) ? rawBinds : defaultBinds();
    const seen = ({});
    const result = [];
    for (const entry of source) {
        if (!entry || typeof entry !== "object") {
            continue;
        }
        const tokens = parseKeySequence(entry.keys);
        const keyPath = tokens.join(" ");
        if (tokens.length === 0 || seen[keyPath]) {
            continue;
        }
        seen[keyPath] = true;

        const description = typeof entry.description === "string" ? entry.description.trim() : "";
        const command = typeof entry.command === "string" ? entry.command.trim() : "";
        const icon = typeof entry.icon === "string" ? entry.icon.trim() : "";
        result.push({
            keys: tokens,
            description: description || (command ? "Action" : "Group"),
            command: command,
            icon: icon
        });
    }

    return result;
}

function normalizeConfig(rawConfig) {
    const source = rawConfig && typeof rawConfig === "object" ? rawConfig : ({});
    const title = typeof source.title === "string" && source.title.trim() ? source.title.trim() : "Leader";
    return ({
        enabled: source.enabled !== false,
        closeOnUnknown: source.closeOnUnknown !== false,
        title: title,
        binds: normalizeBinds(source.binds)
    });
}

function ensureNodeChild(node, key) {
    if (!node.children[key]) {
        node.children[key] = emptyTree();
    }
    return node.children[key];
}

function buildTree(binds) {
    const root = emptyTree();
    root.description = "Leader";
    for (const bind of binds) {
        let node = root;
        for (const key of bind.keys) {
            node = ensureNodeChild(node, key);
        }
        node.description = bind.description;
        node.command = bind.command;
        node.icon = bind.icon;
    }
    return root;
}

function nodeForPath(tree, path) {
    let node = tree;
    for (const key of path) {
        const nextNode = node.children?.[key];
        if (!nextNode) {
            return tree;
        }
        node = nextNode;
    }
    return node;
}

function inferIcon(path, key, entry) {
    const full = `${path.join("")}${key}`;
    if (entry.children && Object.keys(entry.children).length > 0) {
        if (full.startsWith("w")) {
            return "web_asset";
        }
        if (full.startsWith("l")) {
            return "dashboard";
        }
        if (full.startsWith("u")) {
            return "build";
        }
        if (full.startsWith("s")) {
            return "search";
        }
        return "folder";
    }
    return "bolt";
}

function entriesForPath(tree, path) {
    const node = nodeForPath(tree, path);
    const keys = Object.keys(node.children || ({})).sort();
    return keys.map(key => {
        const entry = node.children[key] || emptyTree();
        const childCount = Object.keys(entry.children || ({})).length;
        return ({
            key: key,
            label: keyTokenLabel(key),
            description: entry.description || (childCount > 0 ? "Group" : "Action"),
            icon: entry.icon || inferIcon(path, key, entry),
            command: entry.command || "",
            hasChildren: childCount > 0
        });
    });
}

function crumbLabel(title, path) {
    const prefix = typeof title === "string" && title.trim() ? title.trim() : "Leader";
    if (!Array.isArray(path) || path.length === 0) {
        return prefix;
    }
    return `${prefix} ${path.join(" ").toUpperCase()}`;
}
