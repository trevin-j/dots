pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import "./" as Services
import "../features/bitwarden/vm/BitwardenPickerLogic.js" as BitwardenPickerLogic

/*
  BitwardenService
  Loads Bitwarden entry metadata on demand, filters TOTP-capable entries, and activates selections.
 */
Scope {
    id: root

    readonly property string panelId: "bitwarden"
    readonly property string totpScannerCommand: "if command -v list-rbw-totp-entries >/dev/null 2>&1; then list-rbw-totp-entries; elif [ -x \"$HOME/.dots/hyprland/.local/bin/list-rbw-totp-entries\" ]; then \"$HOME/.dots/hyprland/.local/bin/list-rbw-totp-entries\"; fi"

    property var stateEntries: []
    property var metadataEntries: []
    property var totpPeriods: ({})
    property string mode: "password"
    property bool listLoading: false
    property bool totpLoading: false
    property bool pendingReload: false
    property bool unlockCheckInFlight: false
    property bool unlockInFlight: false
    property string pendingOpenMode: ""
    property int totpHeaderPeriod: 30
    property double currentTimeMs: Date.now()

    function shellQuote(value) {
        const text = typeof value === "string" ? value : "";
        return "'" + text.replace(/'/g, "'\"'\"'") + "'";
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

    function stateEntryForFocusedMonitor() {
        const key = root.focusedMonitorKey();
        if (key === "") {
            return null;
        }

        for (const entry of root.stateEntries) {
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

    function fallbackEntry() {
        for (const entry of root.stateEntries) {
            if (entry && entry.state) {
                return entry;
            }
        }

        return null;
    }

    function targetState() {
        const entry = root.stateEntryForFocusedMonitor() || root.fallbackEntry();
        return entry && entry.state ? entry.state : null;
    }

    function withTargetState(callback) {
        const state = root.targetState();
        if (!state) {
            return;
        }

        callback(state);
    }

    function registerScreenState(screen, state) {
        if (!screen || !state) {
            return;
        }

        const entries = root.stateEntries.filter(entry => entry && entry.state && entry.state !== state);
        entries.push({ screen: screen, state: state });
        root.stateEntries = entries;
    }

    function unregisterScreenState(state) {
        if (!state) {
            return;
        }

        root.stateEntries = root.stateEntries.filter(entry => entry && entry.state && entry.state !== state);
    }

    function clearEntries() {
        root.metadataEntries = [];
        root.totpPeriods = ({ });
        root.totpHeaderPeriod = 30;
    }

    function closeAll() {
        for (const entry of root.stateEntries) {
            if (entry && entry.state) {
                entry.state.close();
            }
        }
    }

    function close() {
        root.withTargetState(state => state.close());
    }

    function isOpen() {
        for (const entry of root.stateEntries) {
            if (entry && entry.state && entry.state.open) {
                return true;
            }
        }

        return false;
    }

    function updateTotpHeaderPeriod() {
        for (const entry of root.metadataEntries) {
            const period = root.totpPeriods[entry.id];
            if (period) {
                root.totpHeaderPeriod = period;
                return;
            }
        }

        root.totpHeaderPeriod = 30;
    }

    function emptyTextForMode(rawMode, query) {
        const mode = BitwardenPickerLogic.normalizeMode(rawMode);
        const searching = typeof query === "string" && query.trim() !== "";
        if (root.listLoading) {
            return "Unlocking and loading Bitwarden...";
        }
        if (mode === "totp" && root.totpLoading) {
            return "Scanning Bitwarden for TOTP entries...";
        }
        if (searching) {
            if (mode === "totp") {
                return "No matching TOTP entries";
            }
            if (mode === "username") {
                return "No matching usernames";
            }
            return "No matching Bitwarden entries";
        }
        if (mode === "totp") {
            return "No Bitwarden entries with TOTP found";
        }
        if (mode === "username") {
            return "No Bitwarden usernames found";
        }
        return "No Bitwarden entries found";
    }

    function reloadCurrentMode() {
        if (root.listLoading || root.totpLoading) {
            root.pendingReload = true;
            return;
        }

        root.clearEntries();
        root.currentTimeMs = Date.now();
        root.listLoading = true;
        listProcess.exec(["rbw", "list", "--fields", "id,name,user,folder,type"]);
    }

    function finalizeOpenMode(rawMode) {
        const state = root.targetState();
        if (!state) {
            return;
        }

        root.mode = BitwardenPickerLogic.normalizeMode(rawMode);
        Services.PanelExclusivityService.requestOpen(root.panelId);
        root.closeAll();
        root.reloadCurrentMode();
        state.openPanel(root.mode);
    }

    function ensureUnlockedAndOpenMode(rawMode) {
        root.pendingOpenMode = BitwardenPickerLogic.normalizeMode(rawMode);
        root.closeAll();

        if (root.unlockCheckInFlight || root.unlockInFlight) {
            return;
        }

        root.unlockCheckInFlight = true;
        unlockCheckProcess.exec([
            "/bin/sh",
            "-lc",
            "if rbw unlocked >/dev/null 2>&1; then printf unlocked; else printf locked; fi"
        ]);
    }

    function openMode(rawMode) {
        root.ensureUnlockedAndOpenMode(rawMode);
    }

    function toggleMode(rawMode) {
        const state = root.targetState();
        const mode = BitwardenPickerLogic.normalizeMode(rawMode);
        if (state && state.open && state.mode === mode) {
            root.close();
            return;
        }

        root.openMode(mode);
    }

    function startTotpScan() {
        const ids = root.metadataEntries.map(entry => entry.id).filter(Boolean);
        if (ids.length === 0) {
            root.totpLoading = false;
            return;
        }

        root.totpLoading = true;
        const payload = ids.join("\n") + "\n";
        totpScanProcess.exec([
            "/bin/sh",
            "-lc",
            "printf '%s' " + root.shellQuote(payload) + " | " + root.totpScannerCommand
        ]);
    }

    function activateEntry(rawMode, item) {
        if (!item || !item.id) {
            return;
        }

        const mode = BitwardenPickerLogic.normalizeMode(rawMode);
        if (mode === "username") {
            const username = typeof item.username === "string" ? item.username : "";
            if (!username) {
                return;
            }

            activateProcess.exec([
                "/bin/sh",
                "-lc",
                "printf '%s' " + root.shellQuote(username) + " | wtype -"
            ]);
            return;
        }

        if (mode === "totp") {
            activateProcess.exec([
                "/bin/sh",
                "-lc",
                "rbw code " + root.shellQuote(item.id) + " | sed -z 's/\\n$//' | wtype -"
            ]);
            return;
        }

        activateProcess.exec([
            "/bin/sh",
            "-lc",
            "rbw get " + root.shellQuote(item.id) + " | sed -z 's/\\n$//' | wtype -"
        ]);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.isOpen() && root.mode === "totp"
        onTriggered: root.currentTimeMs = Date.now()
    }

    Process {
        id: listProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.listLoading = false;
                if (root.pendingReload) {
                    root.pendingReload = false;
                    root.reloadCurrentMode();
                    return;
                }

                root.metadataEntries = BitwardenPickerLogic.parseListText(text);
                if (root.mode === "totp") {
                    root.startTotpScan();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService list failed", output);
                }
            }
        }
    }

    Process {
        id: unlockCheckProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.unlockCheckInFlight = false;
                if (text.trim() === "unlocked") {
                    root.finalizeOpenMode(root.pendingOpenMode);
                    return;
                }

                if (root.unlockInFlight) {
                    return;
                }

                root.unlockInFlight = true;
                unlockProcess.exec([
                    "/bin/sh",
                    "-lc",
                    "if rbw unlock >/dev/null 2>&1; then printf unlocked; else printf failed; fi"
                ]);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.unlockCheckInFlight = false;
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService unlock check failed", output);
                }
            }
        }
    }

    Process {
        id: unlockProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.unlockInFlight = false;
                if (text.trim() === "unlocked") {
                    root.finalizeOpenMode(root.pendingOpenMode);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.unlockInFlight = false;
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService unlock failed", output);
                }
            }
        }
    }

    Process {
        id: totpScanProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.totpLoading = false;
                if (root.pendingReload) {
                    root.pendingReload = false;
                    root.reloadCurrentMode();
                    return;
                }

                root.totpPeriods = BitwardenPickerLogic.parseTotpScanText(text);
                root.updateTotpHeaderPeriod();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService TOTP scan failed", output);
                }
            }
        }
    }

    Process {
        id: activateProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService activate failed", output);
                }
            }
        }
    }

    IpcHandler {
        target: "bitwarden"

        function togglePassword(): void {
            root.toggleMode("password");
        }

        function toggleUsername(): void {
            root.toggleMode("username");
        }

        function toggleTotp(): void {
            root.toggleMode("totp");
        }

        function close(): void {
            root.close();
        }
    }
}
