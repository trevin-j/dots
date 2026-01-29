pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.platform as Platform

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

    Component.onCompleted: {
        console.log("ThemeStore path", palettePath);
        console.log("ThemeStore current keys", Object.keys(current));
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
                console.log("ThemeStore loaded bytes", rawText.length);
                const parsed = JSON.parse(rawText);
                root.mode = parsed.mode || root.mode;
                root.light = parsed.light || ({});
                root.dark = parsed.dark || ({});
                console.log("ThemeStore mode", root.mode, "dark keys", Object.keys(root.dark).length, "surface", root.dark.surface_container);
                root.ready = true;
                root._loaded = true;
                root.loaded();
            } catch (error) {
                console.warn("ThemeStore: failed to parse palette.json", error);
            }
        }

        onLoadFailed: {
            console.warn("ThemeStore: failed to load palette.json", errorString);
        }
    }
}
