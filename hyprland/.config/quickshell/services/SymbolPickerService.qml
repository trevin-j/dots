pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Qt.labs.platform as Platform

import "./" as Services
import "parsers/SymbolPickerParsers.js" as SymbolPickerParsers

/*
  SymbolPickerService
  Loads emoji and nerd-font data, tracks MRU usage, and manages picker IPC/state.
 */
Scope {
    id: root

    readonly property string panelId: "symbolpicker"
    property var stateEntries: ({ emoji: [], nerdfont: [] })
    readonly property string dataDirPath: Platform.StandardPaths.writableLocation(Platform.StandardPaths.GenericDataLocation)
        + "/quickshell/symbol-picker"
    readonly property string updaterCommand: "if command -v update-quickshell-symbol-data >/dev/null 2>&1; then update-quickshell-symbol-data --quiet; elif [ -x \"$HOME/.dots/hyprland/.local/bin/update-quickshell-symbol-data\" ]; then \"$HOME/.dots/hyprland/.local/bin/update-quickshell-symbol-data\" --quiet; fi"
    readonly property string cacheBuilderCommand: "if command -v build-quickshell-symbol-cache >/dev/null 2>&1; then build-quickshell-symbol-cache \"$@\"; elif [ -x \"$HOME/.dots/hyprland/.local/bin/build-quickshell-symbol-cache\" ]; then \"$HOME/.dots/hyprland/.local/bin/build-quickshell-symbol-cache\" \"$@\"; fi"

    readonly property string emojiDataPath: Quickshell.env("QS_EMOJI_DATA_PATH") || (root.dataDirPath + "/emoji.json")
    readonly property string emojiDataFilePath: SymbolPickerParsers.normalizeFileSystemPath(root.emojiDataPath)
    readonly property string nerdFontDataPath: Quickshell.env("QS_NERD_FONT_DATA_PATH") || (root.dataDirPath + "/nerd-font-icons.json")
    readonly property string nerdFontDataFilePath: SymbolPickerParsers.normalizeFileSystemPath(root.nerdFontDataPath)
    readonly property string emojiMruPath: Quickshell.env("QS_EMOJI_MRU_PATH")
        || (root.dataDirPath + "/emoji-mru")
    readonly property string emojiMruFilePath: SymbolPickerParsers.normalizeFileSystemPath(root.emojiMruPath)
    readonly property string nerdFontMruPath: Quickshell.env("QS_NERD_FONT_MRU_PATH")
        || (root.dataDirPath + "/nerdfont-mru")
    readonly property string nerdFontMruFilePath: SymbolPickerParsers.normalizeFileSystemPath(root.nerdFontMruPath)
    readonly property string emojiCachePath: root.dataDirPath + "/emoji-cache.json"
    readonly property string emojiCacheFilePath: SymbolPickerParsers.normalizeFileSystemPath(root.emojiCachePath)
    readonly property string nerdFontCachePath: root.dataDirPath + "/nerdfont-cache.json"
    readonly property string nerdFontCacheFilePath: SymbolPickerParsers.normalizeFileSystemPath(root.nerdFontCachePath)

    property var emojiUsageCounts: ({})
    property var nerdFontUsageCounts: ({})
    property var emojiEntries: []
    property var nerdFontEntries: []
    property string pendingActivationKind: ""
    property string pendingActivationGlyph: ""
    property bool emojiDirty: false
    property bool nerdFontDirty: false
    property bool emojiLoadRequested: false
    property bool nerdFontLoadRequested: false
    property bool emojiLoaded: false
    property bool nerdFontLoaded: false
    property bool emojiBuildInFlight: false
    property bool nerdFontBuildInFlight: false

    readonly property string _appendScript: "import pathlib, sys; p = pathlib.Path(sys.argv[1]).expanduser(); p.parent.mkdir(parents=True, exist_ok=True); f = p.open('a', encoding='utf-8'); f.write(sys.argv[2]); f.write('\\n'); f.close()"

    function shellQuote(value) {
        const text = typeof value === "string" ? value : "";
        return `'${text.replace(/'/g, `'"'"'`)}'`;
    }

    function monitorKey(monitor) {
        if (!monitor) {
            return "";
        }

        return monitor.name
            || monitor.connector
            || monitor.id
            || ((monitor.lastIpcObject && monitor.lastIpcObject.name) ? monitor.lastIpcObject.name : "")
            || "";
    }

    function focusedMonitorKey() {
        return root.monitorKey(Hyprland.focusedMonitor);
    }

    function entriesForKind(kind) {
        const key = kind === "emoji" ? "emoji" : "nerdfont";
        const entries = root.stateEntries[key];
        return Array.isArray(entries) ? entries : [];
    }

    function setEntriesForKind(kind, entries) {
        const key = kind === "emoji" ? "emoji" : "nerdfont";
        root.stateEntries = Object.assign({}, root.stateEntries, {
            [key]: entries
        });
    }

    function stateEntryForFocusedMonitor(kind) {
        const key = root.focusedMonitorKey();
        if (key === "") {
            return null;
        }

        for (const entry of root.entriesForKind(kind)) {
            if (!entry || !entry.screen || !entry.state) {
                continue;
            }

            const monitor = Hyprland.monitorFor(entry.screen);
            if (root.monitorKey(monitor) === key) {
                return entry;
            }
        }

        return null;
    }

    function fallbackEntry(kind) {
        for (const entry of root.entriesForKind(kind)) {
            if (entry && entry.state) {
                return entry;
            }
        }

        return null;
    }

    function targetState(kind) {
        const entry = root.stateEntryForFocusedMonitor(kind) || root.fallbackEntry(kind);
        return entry && entry.state ? entry.state : null;
    }

    function withTargetState(kind, callback) {
        const state = root.targetState(kind);
        if (!state) {
            return;
        }

        callback(state);
    }

    function registerScreenState(kind, screen, state) {
        if (!screen || !state) {
            return;
        }

        const entries = root.entriesForKind(kind).filter(entry => entry && entry.state && entry.state !== state);
        entries.push({ screen: screen, state: state });
        root.setEntriesForKind(kind, entries);
    }

    function unregisterScreenState(kind, state) {
        if (!state) {
            return;
        }

        root.setEntriesForKind(kind, root.entriesForKind(kind).filter(entry => entry && entry.state && entry.state !== state));
    }

    function parseCacheText(text) {
        try {
            const parsed = text ? JSON.parse(text) : [];
            return Array.isArray(parsed) ? parsed : [];
        } catch (_error) {
            return [];
        }
    }

    function loadEmojiCache() {
        emojiCacheFile.reload();
    }

    function loadNerdFontCache() {
        nerdFontCacheFile.reload();
    }

    function rebuildKind(kind) {
        if (kind === "emoji") {
            root.emojiDirty = false;
            root.queueBuildKind("emoji");
            return;
        }

        root.nerdFontDirty = false;
        root.queueBuildKind("nerdfont");
    }

    function ensureKindLoaded(kind) {
        if (kind === "emoji") {
            if (!root.emojiLoadRequested) {
                root.emojiLoadRequested = true;
            }
            if (!root.emojiLoaded && !root.emojiBuildInFlight) {
                root.queueBuildKind("emoji");
            }
            return;
        }

        if (!root.nerdFontLoadRequested) {
            root.nerdFontLoadRequested = true;
        }
        if (!root.nerdFontLoaded && !root.nerdFontBuildInFlight) {
            root.queueBuildKind("nerdfont");
        }
    }

    function isKindLoaded(kind) {
        return kind === "emoji" ? root.emojiLoaded : root.nerdFontLoaded;
    }

    function isKindLoading(kind) {
        return kind === "emoji"
            ? (root.emojiBuildInFlight || (root.emojiLoadRequested && !root.emojiLoaded))
            : (root.nerdFontBuildInFlight || (root.nerdFontLoadRequested && !root.nerdFontLoaded));
    }

    function queueBuildKind(kind) {
        if (kind === "emoji") {
            if (root.emojiBuildInFlight) {
                return;
            }
            root.emojiBuildInFlight = true;
            buildEmojiCacheProcess.exec([
                "/bin/sh",
                "-lc",
                `${root.cacheBuilderCommand}`,
                "build-quickshell-symbol-cache",
                "--kind",
                "emoji",
                "--data-file",
                root.emojiDataFilePath,
                "--mru-file",
                root.emojiMruFilePath,
                "--cache-file",
                root.emojiCacheFilePath
            ]);
            return;
        }

        if (root.nerdFontBuildInFlight) {
            return;
        }
        root.nerdFontBuildInFlight = true;
        buildNerdFontCacheProcess.exec([
            "/bin/sh",
            "-lc",
            `${root.cacheBuilderCommand}`,
            "build-quickshell-symbol-cache",
            "--kind",
            "nerdfont",
            "--data-file",
            root.nerdFontDataFilePath,
            "--mru-file",
            root.nerdFontMruFilePath,
            "--cache-file",
            root.nerdFontCacheFilePath
        ]);
    }

    function closeAll() {
        root.cancelPendingActivation();
        for (const kind of ["emoji", "nerdfont"]) {
            for (const entry of root.entriesForKind(kind)) {
                if (entry && entry.state) {
                    entry.state.close();
                }
            }
        }
    }

    function openKind(kind) {
        const state = root.targetState(kind);
        if (!state) {
            return;
        }

        Services.PanelExclusivityService.requestOpen(root.panelId);
        root.closeAll();
        root.ensureKindLoaded(kind);
        if (root.isKindLoaded(kind) && ((kind === "emoji" && root.emojiDirty) || (kind === "nerdfont" && root.nerdFontDirty))) {
            root.rebuildKind(kind);
        }
        state.openPanel();
    }

    function toggleKind(kind) {
        if (root.isTargetOpen(kind)) {
            root.closeKind(kind);
            return;
        }

        root.openKind(kind);
    }

    function closeKind(kind) {
        root.withTargetState(kind, state => state.close());
    }

    function isTargetOpen(kind) {
        const state = root.targetState(kind);
        return state ? state.open : false;
    }

    function appendUsage(kind, glyph) {
        const text = typeof glyph === "string" ? glyph : "";
        if (!text) {
            return;
        }

        if (kind === "emoji") {
            root.emojiUsageCounts = SymbolPickerParsers.recordUsage(root.emojiUsageCounts, text);
            root.emojiDirty = true;
            appendMruProcess.exec(["python3", "-c", root._appendScript, root.emojiMruFilePath, text]);
            return;
        }

        root.nerdFontUsageCounts = SymbolPickerParsers.recordUsage(root.nerdFontUsageCounts, text);
        root.nerdFontDirty = true;
        appendMruProcess.exec(["python3", "-c", root._appendScript, root.nerdFontMruFilePath, text]);
    }

    function refreshDataFiles() {
        if (root.emojiLoadRequested || root.emojiLoaded) {
            root.queueBuildKind("emoji");
        }
        if (root.nerdFontLoadRequested || root.nerdFontLoaded) {
            root.queueBuildKind("nerdfont");
        }
    }

    function refreshMruFiles() {
        emojiMruFile.reload();
        nerdFontMruFile.reload();
    }

    function updateDataFiles() {
        dataUpdateProcess.exec(["/bin/sh", "-lc", root.updaterCommand]);
    }

    function activateGlyph(kind, glyph) {
        const text = typeof glyph === "string" ? glyph : "";
        if (!text) {
            return;
        }

        root.pendingActivationKind = kind === "emoji" ? "emoji" : "nerdfont";
        root.pendingActivationGlyph = text;
        activationTimer.restart();
    }

    function cancelPendingActivation() {
        activationTimer.stop();
        root.pendingActivationKind = "";
        root.pendingActivationGlyph = "";
    }

    FileView {
        id: emojiCacheFile

        path: root.emojiLoadRequested ? root.emojiCacheFilePath : ""
        watchChanges: false
        blockLoading: false
        onLoaded: {
            root.emojiEntries = root.parseCacheText(emojiCacheFile.text());
            root.emojiLoaded = true;
        }
        onLoadFailed: {
            root.emojiEntries = [];
            root.emojiLoaded = true;
        }
    }

    FileView {
        id: nerdFontCacheFile

        path: root.nerdFontLoadRequested ? root.nerdFontCacheFilePath : ""
        watchChanges: false
        blockLoading: false
        onLoaded: {
            root.nerdFontEntries = root.parseCacheText(nerdFontCacheFile.text());
            root.nerdFontLoaded = true;
        }
        onLoadFailed: {
            root.nerdFontEntries = [];
            root.nerdFontLoaded = true;
        }
    }

    FileView {
        id: emojiMruFile

        path: root.emojiMruFilePath
        watchChanges: false
        blockLoading: false
        onLoaded: {
            root.emojiUsageCounts = SymbolPickerParsers.parseUsageText(emojiMruFile.text());
        }
        onLoadFailed: {
            root.emojiUsageCounts = ({});
        }
    }

    FileView {
        id: nerdFontMruFile

        path: root.nerdFontMruFilePath
        watchChanges: false
        blockLoading: false
        onLoaded: {
            root.nerdFontUsageCounts = SymbolPickerParsers.parseUsageText(nerdFontMruFile.text());
        }
        onLoadFailed: {
            root.nerdFontUsageCounts = ({});
        }
    }

    Timer {
        id: activationTimer

        interval: 45
        repeat: false
        onTriggered: {
            const kind = root.pendingActivationKind;
            const text = root.pendingActivationGlyph;
            root.pendingActivationKind = "";
            root.pendingActivationGlyph = "";
            if (!text) {
                return;
            }

            activateProcess.exec([
                "/bin/sh",
                "-lc",
                `printf '%s' ${root.shellQuote(text)} | wtype -`
            ]);
            root.appendUsage(kind, text);
        }
    }

    Timer {
        id: preloadTimer

        interval: 1500
        repeat: false
        onTriggered: {
            root.emojiLoadRequested = true;
            root.nerdFontLoadRequested = true;
            root.queueBuildKind("emoji");
            root.queueBuildKind("nerdfont");
        }
    }

    Process {
        id: activateProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("SymbolPickerService activate failed", output);
                }
            }
        }
    }

    Process {
        id: appendMruProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("SymbolPickerService MRU append failed", output);
                }
            }
        }
    }

    Process {
        id: dataUpdateProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.refreshDataFiles();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("SymbolPickerService data update failed", output);
                }
                root.refreshDataFiles();
            }
        }
    }

    Process {
        id: buildEmojiCacheProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.emojiBuildInFlight = false;
                root.loadEmojiCache();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.emojiBuildInFlight = false;
                const output = text.trim();
                if (output) {
                    console.warn("SymbolPickerService emoji cache build failed", output);
                }
                root.loadEmojiCache();
            }
        }
    }

    Process {
        id: buildNerdFontCacheProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.nerdFontBuildInFlight = false;
                root.loadNerdFontCache();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.nerdFontBuildInFlight = false;
                const output = text.trim();
                if (output) {
                    console.warn("SymbolPickerService Nerd Font cache build failed", output);
                }
                root.loadNerdFontCache();
            }
        }
    }

    IpcHandler {
        target: "emoji"

        function toggle() {
            root.toggleKind("emoji");
        }

        function open() {
            root.openKind("emoji");
        }

        function close() {
            root.closeKind("emoji");
        }

        function isOpen() {
            return root.isTargetOpen("emoji");
        }
    }

    IpcHandler {
        target: "nerdfont"

        function toggle() {
            root.toggleKind("nerdfont");
        }

        function open() {
            root.openKind("nerdfont");
        }

        function close() {
            root.closeKind("nerdfont");
        }

        function isOpen() {
            return root.isTargetOpen("nerdfont");
        }
    }

    Component.onCompleted: {
        Services.PanelExclusivityService.registerPanel(root.panelId, root);
        root.refreshMruFiles();
        root.updateDataFiles();
        preloadTimer.start();
    }
    Component.onDestruction: Services.PanelExclusivityService.unregisterPanel(root.panelId, root)
}
