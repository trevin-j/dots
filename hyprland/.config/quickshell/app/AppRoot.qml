import QtQuick
import Quickshell

import "../features/osd" as OsdFeature
import "./" as App

ShellRoot {
    Variants {
        model: Quickshell.screens

        App.ScreenShell {
            required property var modelData
            panelScreen: modelData
        }
    }

    OsdFeature.VolumePopupLayerFeature {}
    OsdFeature.BrightnessPopupLayerFeature {}
}
