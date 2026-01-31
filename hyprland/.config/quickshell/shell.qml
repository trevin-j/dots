//@ pragma UseQApplication
import QtQuick
import Quickshell

import "modules/bar"
import "modules/volume"
import "modules/brightness"
import "modules/frame"

ShellRoot {
    id: root


    Variants {
        model: Quickshell.screens

        FrameOverlay {
            required property var modelData
            panelScreen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        BarPanel {
            required property var modelData
            panelScreen: modelData
        }
    }

    VolumePopupLayer {}
    BrightnessPopupLayer {}
}
