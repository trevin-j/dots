pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string configPath: Quickshell.env("QS_CONFIG_PATH") || Qt.resolvedUrl("config.json")

    property bool ready: false
    property bool _loaded: false

    property var overrides: ({})

    signal loaded()

    function markReadyWithDefaults() {
        root.overrides = ({});
        root.ready = true;
        root._loaded = true;
        root.loaded();
    }

    FileView {
        id: configFile

        path: root.configPath
        watchChanges: true
        blockLoading: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const rawText = configFile.text();
                const parsed = rawText ? JSON.parse(rawText) : ({});
                root.overrides = parsed && typeof parsed === "object" ? parsed : ({});
                root.ready = true;
                root._loaded = true;
                root.loaded();
            } catch (error) {
                console.warn("ConfigStore: failed to parse config.json", error);
                root.markReadyWithDefaults();
            }
        }

        onLoadFailed: {
            console.warn("ConfigStore: failed to load config.json", errorString);
            root.markReadyWithDefaults();
        }
    }
}
