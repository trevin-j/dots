pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string configPath: Quickshell.env("QS_CONFIG_PATH") || Qt.resolvedUrl("config.json")

    property bool ready: false
    property bool _saving: false
    property bool _loaded: false

    property var data: ({})

    signal loaded()

    Component.onCompleted: {
        console.log("ConfigStore path", configPath);
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
                console.log("ConfigStore loaded bytes", rawText.length);
                root.data = JSON.parse(rawText);
                root.ready = true;
                root._loaded = true;
                root.loaded();
            } catch (error) {
                console.warn("ConfigStore: failed to parse config.json", error);
            }
        }

        onLoadFailed: {
            console.warn("ConfigStore: failed to load config.json", errorString);
        }
    }
}
