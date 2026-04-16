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
    property var setupEntries: []
    property var metadataEntries: []
    property var totpPeriods: ({})
    property string mode: "password"
    property bool listLoading: false
    property bool totpLoading: false
    property bool pendingReload: false
    property bool unlockCheckInFlight: false
    property bool unlockInFlight: false
    property bool configCheckInFlight: false
    property bool syncInFlight: false
    property bool lockInFlight: false
    property bool logoutInFlight: false
    property bool setupInFlight: false
    property bool loginInFlight: false
    property string pendingOpenMode: ""
    property string pendingSetupEmail: ""
    property string pendingSetupServerUrl: ""
    property string configuredEmail: ""
    property string configuredBaseUrl: ""
    property bool vaultUnlocked: false
    property bool vaultPurged: false
    property bool vaultConfigured: true
    property int totpHeaderPeriod: 30
    property double currentTimeMs: Date.now()
    readonly property bool vaultBusy: root.configCheckInFlight || root.unlockCheckInFlight || root.unlockInFlight || root.syncInFlight || root.lockInFlight || root.logoutInFlight || root.setupInFlight || root.loginInFlight
    property bool pickerOpenCheckPending: false
    readonly property string authState: root.vaultBusy
        ? "busy"
        : (!root.vaultConfigured
            ? "unconfigured"
            : (root.vaultUnlocked
                ? "unlocked"
                : (root.vaultPurged ? "loginRequired" : "locked")))
    readonly property string vaultStatusText: root.vaultBusy
        ? root.vaultBusyText()
        : (root.authState === "unconfigured"
            ? "Not configured"
            : (root.vaultUnlocked ? "Unlocked" : (root.vaultPurged ? "Logged out" : "Locked")))
    readonly property string vaultDetailText: root.vaultBusy
        ? ""
        : (!root.vaultConfigured
            ? "Bitwarden account and server details must be set again before login."
            : (root.vaultPurged
            ? "The local vault was cleared. Open a picker to sign in again."
            : (root.vaultUnlocked
                ? "Pickers can fetch credentials on demand."
                : "Unlock is required before secrets can be fetched.")))

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

    function registerSetupState(screen, state) {
        if (!screen || !state) {
            return;
        }

        const entries = root.setupEntries.filter(entry => entry && entry.state && entry.state !== state);
        entries.push({ screen: screen, state: state });
        root.setupEntries = entries;
    }

    function unregisterSetupState(state) {
        if (!state) {
            return;
        }

        root.setupEntries = root.setupEntries.filter(entry => entry && entry.state && entry.state !== state);
    }

    function targetSetupState() {
        const key = root.focusedMonitorKey();
        for (const entry of root.setupEntries) {
            if (!entry || !entry.screen || !entry.state) {
                continue;
            }

            const monitor = Hyprland.monitorFor(entry.screen);
            if (key !== "" && root.monitorKey(monitor) === key) {
                return entry.state;
            }
        }

        for (const entry of root.setupEntries) {
            if (entry && entry.state) {
                return entry.state;
            }
        }

        return null;
    }

    function openSetupPrompt() {
        const state = root.targetSetupState();
        if (!state) {
            root.pendingOpenMode = "";
            return;
        }

        state.openDialog(root.configuredEmail, root.configuredBaseUrl);
    }

    function closeSetupPrompt() {
        const state = root.targetSetupState();
        if (state) {
            state.closeDialog();
        }
    }

    function setSetupStateBusy(submitting) {
        const state = root.targetSetupState();
        if (state) {
            state.submitting = !!submitting;
        }
    }

    function setSetupStateError(message) {
        const state = root.targetSetupState();
        if (state) {
            state.errorText = typeof message === "string" ? message : "";
        }
    }

    function clearEntries() {
        root.metadataEntries = [];
        root.totpPeriods = ({ });
        root.totpHeaderPeriod = 30;
    }

    function vaultBusyText() {
        if (root.logoutInFlight) {
            return "Logging out...";
        }
        if (root.loginInFlight) {
            return "Logging in...";
        }
        if (root.setupInFlight) {
            return "Saving account...";
        }
        if (root.configCheckInFlight) {
            return "Checking account...";
        }
        if (root.lockInFlight) {
            return "Locking...";
        }
        if (root.syncInFlight) {
            return "Syncing vault...";
        }
        if (root.unlockInFlight || root.unlockCheckInFlight) {
            return "Unlocking...";
        }

        return "Working...";
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

    function refreshVaultState() {
        if (root.vaultBusy) {
            return;
        }

        root.pickerOpenCheckPending = false;
        root.configCheckInFlight = true;
        configCheckProcess.exec(["rbw", "config", "show"]);
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
            root.pendingOpenMode = "";
            return;
        }

        root.mode = BitwardenPickerLogic.normalizeMode(rawMode);
        Services.PanelExclusivityService.requestOpen(root.panelId);
        root.closeSetupPrompt();
        root.closeAll();
        root.reloadCurrentMode();
        state.openPanel(root.mode);
        root.pendingOpenMode = "";
    }

    function ensureUnlockedAndOpenMode(rawMode) {
        root.pendingOpenMode = BitwardenPickerLogic.normalizeMode(rawMode);
        root.closeAll();

        if (root.vaultBusy) {
            return;
        }

        root.pickerOpenCheckPending = true;
        root.configCheckInFlight = true;
        configCheckProcess.exec(["rbw", "config", "show"]);
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

    function syncVaultAndUnlock() {
        if (root.syncInFlight || root.unlockInFlight) {
            return;
        }

        root.syncInFlight = true;
        syncProcess.exec([
            "/bin/sh",
            "-lc",
            "if rbw sync >/dev/null 2>&1; then printf synced; else printf failed; fi"
        ]);
    }

    function lockVault() {
        if (root.vaultBusy || !root.vaultUnlocked) {
            return;
        }

        root.closeAll();
        root.lockInFlight = true;
        lockProcess.exec([
            "/bin/sh",
            "-lc",
            "if rbw lock >/dev/null 2>&1; then printf locked; else printf failed; fi"
        ]);
    }

    function logoutVault() {
        if (root.vaultBusy) {
            return;
        }

        root.closeAll();
        root.closeSetupPrompt();
        root.clearEntries();
        root.logoutInFlight = true;
        logoutProcess.exec([
            "/bin/sh",
            "-lc",
            "if rbw purge >/dev/null 2>&1; then rbw stop-agent >/dev/null 2>&1 || true; rbw config unset email >/dev/null 2>&1 || true; rbw config unset base_url >/dev/null 2>&1 || true; rbw config unset identity_url >/dev/null 2>&1 || true; rbw config unset ui_url >/dev/null 2>&1 || true; rbw config unset notifications_url >/dev/null 2>&1 || true; rbw config unset sso_id >/dev/null 2>&1 || true; printf loggedout; else printf failed; fi"
        ]);
    }

    function submitSetup(email, serverUrl) {
        const trimmedEmail = typeof email === "string" ? email.trim() : "";
        const trimmedServerUrl = typeof serverUrl === "string" ? serverUrl.trim() : "";
        if (trimmedEmail === "" || root.setupInFlight) {
            return;
        }

        root.pendingSetupEmail = trimmedEmail;
        root.pendingSetupServerUrl = trimmedServerUrl;
        root.setupInFlight = true;
        root.setSetupStateBusy(true);
        root.setSetupStateError("");
        const resetUrls = "rbw config unset identity_url >/dev/null 2>&1 || true; rbw config unset ui_url >/dev/null 2>&1 || true; rbw config unset notifications_url >/dev/null 2>&1 || true; rbw config unset sso_id >/dev/null 2>&1 || true";
        const setBaseUrl = trimmedServerUrl === ""
            ? "rbw config unset base_url >/dev/null 2>&1 || true"
            : ("rbw config set base_url " + root.shellQuote(trimmedServerUrl) + " >/dev/null 2>&1");
        setupConfigProcess.exec([
            "/bin/sh",
            "-lc",
            "if rbw config set email " + root.shellQuote(trimmedEmail) + " >/dev/null 2>&1; then " + setBaseUrl + "; " + resetUrls + "; printf configured; else printf failed; fi"
        ]);
    }

    function loginAndContinuePendingMode() {
        if (root.loginInFlight) {
            return;
        }

        root.loginInFlight = true;
        loginProcess.exec([
            "/bin/sh",
            "-lc",
            "if rbw login >/dev/null 2>&1; then printf loggedin; else printf failed; fi"
        ]);
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
                root.vaultUnlocked = true;
                root.vaultPurged = false;
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
        id: configCheckProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.configCheckInFlight = false;
                let configured = false;
                try {
                    const parsed = JSON.parse(text);
                    configured = !!(parsed && parsed.email);
                    root.configuredEmail = parsed && parsed.email ? String(parsed.email) : "";
                    root.configuredBaseUrl = parsed && parsed.base_url ? String(parsed.base_url) : "";
                } catch (error) {
                    console.warn("BitwardenService failed to parse config", String(error));
                }

                root.vaultConfigured = configured;
                if (!configured) {
                    root.configuredEmail = "";
                    root.configuredBaseUrl = "";
                    root.vaultUnlocked = false;
                    root.vaultPurged = true;
                    if (root.pickerOpenCheckPending && root.pendingOpenMode !== "") {
                        root.pickerOpenCheckPending = false;
                        root.openSetupPrompt();
                        return;
                    }

                    root.pendingOpenMode = "";
                    root.pickerOpenCheckPending = false;
                    return;
                }

                root.pickerOpenCheckPending = false;
                root.unlockCheckInFlight = true;
                unlockCheckProcess.exec([
                    "/bin/sh",
                    "-lc",
                    "if rbw unlocked >/dev/null 2>&1; then printf unlocked; else printf locked; fi"
                ]);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.configCheckInFlight = false;
                const output = text.trim();
                if (output) {
                    root.vaultConfigured = false;
                    root.vaultUnlocked = false;
                    root.configuredEmail = "";
                    root.configuredBaseUrl = "";
                    root.pickerOpenCheckPending = false;
                    console.warn("BitwardenService config check failed", output);
                }
            }
        }
    }

    Process {
        id: setupConfigProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.setupInFlight = false;
                root.setSetupStateBusy(false);
                if (text.trim() === "configured") {
                    root.vaultConfigured = true;
                    root.vaultPurged = true;
                    root.configuredEmail = root.pendingSetupEmail;
                    root.configuredBaseUrl = root.pendingSetupServerUrl;
                    root.closeSetupPrompt();
                    root.loginAndContinuePendingMode();
                    return;
                }

                root.setSetupStateError("Failed to save Bitwarden account settings.");
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.setupInFlight = false;
                root.setSetupStateBusy(false);
                const output = text.trim();
                if (output) {
                    root.setSetupStateError(output);
                    console.warn("BitwardenService setup config failed", output);
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
                    root.vaultConfigured = true;
                    root.vaultUnlocked = true;
                    root.vaultPurged = false;
                    if (root.pendingOpenMode !== "") {
                        root.finalizeOpenMode(root.pendingOpenMode);
                    }
                    return;
                }

                root.vaultUnlocked = false;
                root.vaultConfigured = true;

                if (root.pendingOpenMode === "") {
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
                    root.vaultUnlocked = false;
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
                    root.vaultConfigured = true;
                    root.vaultUnlocked = true;
                    root.vaultPurged = false;
                    root.finalizeOpenMode(root.pendingOpenMode);
                } else {
                    root.vaultUnlocked = false;
                    root.pendingOpenMode = "";
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.unlockInFlight = false;
                const output = text.trim();
                if (output) {
                    root.vaultUnlocked = false;
                    root.pendingOpenMode = "";
                    console.warn("BitwardenService unlock failed", output);
                }
            }
        }
    }

    Process {
        id: syncProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.syncInFlight = false;
                if (text.trim() === "synced") {
                    root.vaultConfigured = true;
                    root.vaultPurged = false;
                    root.unlockInFlight = true;
                    unlockProcess.exec([
                        "/bin/sh",
                        "-lc",
                        "if rbw unlock >/dev/null 2>&1; then printf unlocked; else printf failed; fi"
                    ]);
                    return;
                }

                root.vaultUnlocked = false;
                root.pendingOpenMode = "";
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.syncInFlight = false;
                root.pendingOpenMode = "";
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService sync failed", output);
                }
            }
        }
    }

    Process {
        id: lockProcess

        stderr: StdioCollector {
            onStreamFinished: {
                root.lockInFlight = false;
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService lock failed", output);
                }
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.lockInFlight = false;
                if (text.trim() === "locked") {
                    root.vaultUnlocked = false;
                }
            }
        }
    }

    Process {
        id: logoutProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.logoutInFlight = false;
                if (text.trim() === "loggedout") {
                    root.vaultUnlocked = false;
                    root.vaultPurged = true;
                    root.vaultConfigured = false;
                    root.configuredEmail = "";
                    root.configuredBaseUrl = "";
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.logoutInFlight = false;
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService logout failed", output);
                }
            }
        }
    }

    Process {
        id: loginProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.loginInFlight = false;
                if (text.trim() === "loggedin") {
                    root.vaultConfigured = true;
                    root.vaultPurged = true;
                    root.syncVaultAndUnlock();
                    return;
                }

                root.pendingOpenMode = "";
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.loginInFlight = false;
                const output = text.trim();
                if (output) {
                    console.warn("BitwardenService login failed", output);
                }
                root.pendingOpenMode = "";
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

        function lock(): void {
            root.lockVault();
        }

        function logout(): void {
            root.logoutVault();
        }

        function refreshState(): void {
            root.refreshVaultState();
        }

        function close(): void {
            root.close();
        }
    }
}
