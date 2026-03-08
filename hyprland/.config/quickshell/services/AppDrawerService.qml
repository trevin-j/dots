pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Qt.labs.platform as Platform

import "./" as Services
import "parsers/AppDrawerUsageParsers.js" as AppDrawerUsageParsers

/*
  AppDrawerService
  Tracks per-screen app drawer state, gesture and IPC actions, and frecency usage persistence.
*/
Scope {
    id: root

    property var entries: []
    property var usageMap: ({})
    readonly property string usagePath: Quickshell.env("QS_APP_DRAWER_STATE_PATH")
        || (Platform.StandardPaths.writableLocation(Platform.StandardPaths.GenericStateLocation)
            + "/quickshell/app_drawer_usage.json")
    readonly property string usageFilePath: AppDrawerUsageParsers.normalizeFileSystemPath(root.usagePath)

    property bool _usageReady: false
    property bool _writeInFlight: false
    property bool _pendingWrite: false

    readonly property string _writeScript: "import json, os, pathlib, sys; p = pathlib.Path(sys.argv[1]).expanduser(); payload = json.loads(sys.argv[2]); p.parent.mkdir(parents=True, exist_ok=True); tmp = p.with_suffix(p.suffix + '.tmp'); tmp.write_text(json.dumps(payload, indent=2), encoding='utf-8'); os.replace(tmp, p)"

    function monitorKey(monitor) {
        if (!monitor) {
            return "";
        }

        return monitor.name
            || monitor.connector
            || monitor.id
            || monitor.lastIpcObject?.name
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

        for (const entry of root.entries) {
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
        for (const entry of root.entries) {
            if (entry && entry.state) {
                return entry;
            }
        }

        return null;
    }

    function withTargetState(callback) {
        const entry = root.stateEntryForFocusedMonitor() || root.fallbackEntry();
        if (!entry || !entry.state) {
            return;
        }

        callback(entry.state);
    }

    function targetState() {
        const entry = root.stateEntryForFocusedMonitor() || root.fallbackEntry();
        if (!entry || !entry.state) {
            return null;
        }

        return entry.state;
    }

    function registerScreenState(screen, state) {
        if (!screen || !state) {
            return;
        }

        const filtered = root.entries.filter(entry => entry && entry.state && entry.state !== state);
        filtered.push({
            screen: screen,
            state: state
        });
        root.entries = filtered;
    }

    function unregisterScreenState(state) {
        if (!state) {
            return;
        }

        root.entries = root.entries.filter(entry => entry && entry.state && entry.state !== state);
    }

    function toggle() {
        if (root.isOpen()) {
            root.close();
            return;
        }

        Services.ControlCenterService.close();
        root.open();
    }

    function open() {
        Services.ControlCenterService.close();
        root.withTargetState(state => state.openPanel());
    }

    function close() {
        root.withTargetState(state => state.close());
    }

    function isOpen() {
        const state = root.targetState();
        return state ? state.open : false;
    }

    function swipeUp() {
        if (!root.isOpen()) {
            root.open();
        }
    }

    function queueUsageWrite() {
        usageWriteTimer.restart();
    }

    function writeUsage() {
        if (!root._usageReady || root._writeInFlight) {
            root._pendingWrite = true;
            return;
        }

        root._pendingWrite = false;
        root._writeInFlight = true;
        const payload = AppDrawerUsageParsers.stringifyUsageMap(root.usageMap);
        usageWriteProcess.exec(["python3", "-c", root._writeScript, root.usageFilePath, payload]);
    }

    function markLaunch(desktopId) {
        root.usageMap = AppDrawerUsageParsers.recordLaunch(root.usageMap, desktopId, Date.now());
        root.queueUsageWrite();
    }

    function launchDesktopId(desktopId) {
        const command = AppDrawerUsageParsers.buildGioLaunchCommand(desktopId);
        launchProcess.exec(["/bin/sh", "-lc", command]);
    }

    FileView {
        id: usageFile

        path: root.usageFilePath
        watchChanges: true
        blockLoading: true

        onFileChanged: reload()

        onLoaded: {
            root.usageMap = AppDrawerUsageParsers.parseUsageText(usageFile.text());
            root._usageReady = true;
        }

        onLoadFailed: {
            root.usageMap = ({});
            root._usageReady = true;
        }
    }

    Timer {
        id: usageWriteTimer

        interval: 80
        repeat: false
        onTriggered: root.writeUsage()
    }

    Process {
        id: usageWriteProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root._writeInFlight = false;
                if (root._pendingWrite) {
                    root.writeUsage();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root._writeInFlight = false;
                if (root._pendingWrite) {
                    root.writeUsage();
                }
            }
        }
    }

    Process {
        id: launchProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("AppDrawerService launch failed", output);
                }
            }
        }
    }

    IpcHandler {
        target: "appdrawer"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function isOpen(): bool {
            return root.isOpen();
        }
    }
}
