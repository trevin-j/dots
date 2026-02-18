import QtQuick
import Quickshell

import "../features/bar" as BarFeature
import "../features/frame" as FrameFeature
import "../features/osd" as OsdFeature

ShellRoot {
    Variants {
        model: Quickshell.screens

        FrameFeature.FrameOverlayFeature {
            required property var modelData
            panelScreen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        BarFeature.BarPanelFeature {
            required property var modelData
            panelScreen: modelData
        }
    }

    OsdFeature.VolumePopupLayerFeature {}
    OsdFeature.BrightnessPopupLayerFeature {}
}
