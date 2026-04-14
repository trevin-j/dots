import QtQuick
import Quickshell

import "../features/chrome" as ChromeFeature
import "../features/osd" as OsdFeature
import "../features/notifications" as NotificationFeature
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
    NotificationFeature.NotificationPopupLayerFeature {}
    ChromeFeature.ScreenCornerCutoutsLayerFeature {}
}
