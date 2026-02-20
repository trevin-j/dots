pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "./" as Services
import "parsers/WallpaperParsers.js" as WallpaperParsers

/*
  WallpaperService
  Discovers wallpapers, tracks current selection, and runs matugen apply commands.
*/
Scope {
    id: root

    readonly property string wallpaperDirectory: Config.Config.controlCenter?.wallpaper?.directory ?? "~/Pictures/wallpapers"
    readonly property var wallpaperExtensions: WallpaperParsers.normalizeExtensions(
        Config.Config.controlCenter?.wallpaper?.extensions
    )

    property bool ready: false
    property bool loading: false
    property bool applyInFlight: false
    property string lastError: ""

    property var wallpapers: []
    property string currentWallpaperPath: ""
    property bool darkModeEnabled: false

    readonly property string _discoverScript: "import json, pathlib, sys; root = pathlib.Path(sys.argv[1]).expanduser(); extensions = {item.lower() for item in json.loads(sys.argv[2])}; paths = [];\nif root.exists() and root.is_dir():\n  for candidate in root.rglob('*'):\n    if candidate.is_file() and candidate.suffix.lower() in extensions:\n      paths.append(str(candidate));\nprint(json.dumps(paths))"

    function refreshWallpapers() {
        if (root.loading) {
            return;
        }
        root.loading = true;
        root.lastError = "";
        discoverProcess.exec(["python3", "-c", root._discoverScript, root.wallpaperDirectory, JSON.stringify(root.wallpaperExtensions)]);
    }

    function selectedIndexForCurrent() {
        const idx = WallpaperParsers.indexForPath(root.wallpapers, root.currentWallpaperPath);
        if (idx >= 0) {
            return idx;
        }
        return root.wallpapers.length > 0 ? 0 : -1;
    }

    function setDarkModeEnabled(next) {
        const desired = !!next;
        if (desired === root.darkModeEnabled) {
            return;
        }
        root.darkModeEnabled = desired;
        Services.RuntimeStateService.setDarkModeEnabled(desired);
        if (root.currentWallpaperPath) {
            root.applyWallpaper(root.currentWallpaperPath);
        }
    }

    function applyWallpaper(path) {
        const normalizedPath = typeof path === "string" ? path.trim() : "";
        if (!normalizedPath) {
            return;
        }

        root.currentWallpaperPath = normalizedPath;
        Services.RuntimeStateService.setState(root.currentWallpaperPath, root.darkModeEnabled);
        root.applyInFlight = true;
        root.lastError = "";
        applyProcess.exec(WallpaperParsers.buildMatugenArgs(root.currentWallpaperPath, root.darkModeEnabled));
    }

    function moveSelection(index, delta) {
        const count = root.wallpapers.length;
        if (count <= 0) {
            return -1;
        }
        const base = WallpaperParsers.clampIndex(index, count);
        const next = base >= 0 ? base + Math.round(delta) : 0;
        return WallpaperParsers.clampIndex(next, count);
    }

    function applyIndex(index) {
        const clamped = WallpaperParsers.clampIndex(index, root.wallpapers.length);
        if (clamped < 0) {
            return;
        }
        root.applyWallpaper(root.wallpapers[clamped]);
    }

    Connections {
        target: Services.RuntimeStateService

        function onReadyChanged() {
            if (!Services.RuntimeStateService.ready) {
                return;
            }
            root.currentWallpaperPath = Services.RuntimeStateService.wallpaperPath;
            root.darkModeEnabled = Services.RuntimeStateService.darkModeEnabled;
            if (!root.ready) {
                root.refreshWallpapers();
            }
        }

        function onWallpaperPathChanged() {
            if (root.currentWallpaperPath !== Services.RuntimeStateService.wallpaperPath) {
                root.currentWallpaperPath = Services.RuntimeStateService.wallpaperPath;
            }
        }

        function onDarkModeEnabledChanged() {
            if (root.darkModeEnabled !== Services.RuntimeStateService.darkModeEnabled) {
                root.darkModeEnabled = Services.RuntimeStateService.darkModeEnabled;
            }
        }
    }

    Process {
        id: discoverProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const parsed = WallpaperParsers.sortedImagePaths(
                    WallpaperParsers.parseDiscoveryOutput(text)
                );
                root.wallpapers = parsed;
                root.ready = true;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const output = text.trim();
                if (output) {
                    root.lastError = output;
                }
            }
        }
    }

    Process {
        id: applyProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.applyInFlight = false;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.applyInFlight = false;
                const output = text.trim();
                if (output) {
                    root.lastError = output;
                }
            }
        }
    }
}
