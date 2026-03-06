pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../config" as Config
import "parsers/VolumeFeedbackParsers.js" as VolumeFeedbackParsers

/*
  VolumeFeedbackService
  Plays configured volume feedback audio when level changes up or down.
*/
Scope {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string builtinBasePath: VolumeFeedbackParsers.urlToLocalPath(
        Qt.resolvedUrl("../assets/sounds/volume/")
    )
    readonly property string configuredSound: {
        const value = Config.Config.popouts?.volume?.sound;
        return typeof value === "string" ? value : "";
    }
    readonly property bool suppressWhenMicActive: VolumeFeedbackParsers.normalizeSuppressWhenMicActive(
        Config.Config.popouts?.volume?.suppressWhenMicActive
    )
    readonly property string soundPath: VolumeFeedbackParsers.resolveSoundPath(
        root.configuredSound,
        root.builtinBasePath,
        root.homeDir
    )

    function playForDelta(delta) {
        const direction = VolumeFeedbackParsers.directionForDelta(delta);
        if (!direction) {
            return;
        }

        root.playDirection(direction);
    }

    function playDirection(direction) {
        if (direction !== "up" && direction !== "down") {
            return;
        }

        if (!root.soundPath) {
            return;
        }

        playProcess.exec([
            "/bin/sh",
            "-lc",
            VolumeFeedbackParsers.buildPlayCommand(root.soundPath, root.suppressWhenMicActive)
        ]);
    }

    Process {
        id: playProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output) {
                    console.warn("VolumeFeedbackService playback failed", output);
                }
            }
        }
    }
}
