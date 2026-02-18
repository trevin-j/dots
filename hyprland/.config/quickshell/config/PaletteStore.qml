pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.platform as Platform
import "PaletteUtils.js" as PaletteUtils

Item {
    id: root

    readonly property string palettePath: Quickshell.env("QS_PALETTE_PATH")
        || (Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation)
            + "/.config/quickshell/config/palette.json")

    property bool ready: false
    property bool _loaded: false

    property string mode: "dark"
    property var light: ({})
    property var dark: ({})

    readonly property var current: mode === "light" ? light : dark

    signal loaded

    function markReadyWithDefaults() {
        const sanitized = PaletteUtils.sanitizePaletteData(({}), root.mode, root.light, root.dark);
        root.mode = sanitized.mode;
        root.light = sanitized.light;
        root.dark = sanitized.dark;
        root.ready = true;
        root._loaded = true;
        root.loaded();
    }

    FileView {
        id: paletteFile

        path: root.palettePath
        watchChanges: true
        blockLoading: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const rawText = paletteFile.text();
                const parsed = JSON.parse(rawText);
                const sanitized = PaletteUtils.sanitizePaletteData(parsed, root.mode, root.light, root.dark);
                root.mode = sanitized.mode;
                root.light = sanitized.light;
                root.dark = sanitized.dark;
                root.ready = true;
                root._loaded = true;
                root.loaded();
            } catch (error) {
                console.warn("ThemeStore: failed to parse palette.json", error);
                root.markReadyWithDefaults();
            }
        }

        onLoadFailed: {
            console.warn("ThemeStore: failed to load palette.json", errorString);
            root.markReadyWithDefaults();
        }
    }
}
