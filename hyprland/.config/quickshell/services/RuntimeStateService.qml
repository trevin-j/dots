pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.platform as Platform

import "parsers/RuntimeStateParsers.js" as RuntimeStateParsers

/*
  RuntimeStateService
  Persists lightweight runtime state used across shell restarts.
*/
Scope {
    id: root

    readonly property string statePath: Quickshell.env("QS_RUNTIME_STATE_PATH")
        || (Platform.StandardPaths.writableLocation(Platform.StandardPaths.GenericStateLocation)
            + "/quickshell/runtime_state.json")
    readonly property string stateFilePath: RuntimeStateParsers.normalizeFileSystemPath(root.statePath)

    property bool ready: false
    property string wallpaperPath: ""
    property bool darkModeEnabled: false
    property bool notificationsDndEnabled: false

    property bool _writeInFlight: false
    property bool _pendingWrite: false

    onReadyChanged: {
        if (root.ready && root._pendingWrite && !root._writeInFlight) {
            root.writeState();
        }
    }

    readonly property string _writeScript: "import json, os, pathlib, sys; p = pathlib.Path(sys.argv[1]).expanduser(); payload = json.loads(sys.argv[2]); p.parent.mkdir(parents=True, exist_ok=True); tmp = p.with_suffix(p.suffix + '.tmp'); tmp.write_text(json.dumps(payload, indent=2), encoding='utf-8'); os.replace(tmp, p)"

    function loadDefaults() {
        const sanitized = RuntimeStateParsers.sanitizeState(({}));
        root.wallpaperPath = sanitized.wallpaperPath;
        root.darkModeEnabled = sanitized.darkModeEnabled;
        root.notificationsDndEnabled = sanitized.notificationsDndEnabled;
        root.ready = true;
    }

    function loadFromText(text) {
        const sanitized = RuntimeStateParsers.parseStateText(text);
        root.wallpaperPath = sanitized.wallpaperPath;
        root.darkModeEnabled = sanitized.darkModeEnabled;
        root.notificationsDndEnabled = sanitized.notificationsDndEnabled;
        root.ready = true;
    }

    function writeState() {
        if (!root.ready || root._writeInFlight) {
            root._pendingWrite = true;
            return;
        }

        root._pendingWrite = false;
        root._writeInFlight = true;
        const payload = RuntimeStateParsers.stringifyState({
            wallpaperPath: root.wallpaperPath,
            darkModeEnabled: root.darkModeEnabled,
            notificationsDndEnabled: root.notificationsDndEnabled
        });
        writeProcess.exec(["python3", "-c", root._writeScript, root.stateFilePath, payload]);
    }

    function queueWrite() {
        writeTimer.restart();
    }

    function setWallpaperPath(path) {
        const nextPath = typeof path === "string" ? path.trim() : "";
        if (nextPath === root.wallpaperPath) {
            return;
        }
        root.wallpaperPath = nextPath;
        root.queueWrite();
    }

    function setDarkModeEnabled(next) {
        const desired = !!next;
        if (desired === root.darkModeEnabled) {
            return;
        }
        root.darkModeEnabled = desired;
        root.queueWrite();
    }

    function setState(path, darkEnabled) {
        const nextPath = typeof path === "string" ? path.trim() : "";
        const nextDark = !!darkEnabled;
        const changed = nextPath !== root.wallpaperPath || nextDark !== root.darkModeEnabled;
        if (!changed) {
            return;
        }
        root.wallpaperPath = nextPath;
        root.darkModeEnabled = nextDark;
        root.queueWrite();
    }

    function setNotificationsDndEnabled(next) {
        const desired = !!next;
        if (desired === root.notificationsDndEnabled) {
            return;
        }

        root.notificationsDndEnabled = desired;
        root.queueWrite();
    }

    FileView {
        id: stateFile

        path: root.stateFilePath
        watchChanges: true
        blockLoading: true

        onFileChanged: reload()

        onLoaded: {
            root.loadFromText(stateFile.text());
        }

        onLoadFailed: {
            root.loadDefaults();
        }
    }

    Timer {
        id: writeTimer

        interval: 80
        repeat: false
        onTriggered: root.writeState()
    }

    Process {
        id: writeProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root._writeInFlight = false;
                if (root._pendingWrite) {
                    root.writeState();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root._writeInFlight = false;
                if (root._pendingWrite) {
                    root.writeState();
                }
            }
        }
    }
}
