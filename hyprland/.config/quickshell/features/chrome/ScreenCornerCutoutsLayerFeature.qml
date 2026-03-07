import QtQuick
import Quickshell

import "./" as ChromeFeature

/*
  ScreenCornerCutoutsLayerFeature
  Mounts one screen-corner chrome window per screen as the last global shell layer.
*/
Scope {
    Variants {
        model: Quickshell.screens

        ChromeFeature.ScreenCornerCutoutsFeature {
            required property var modelData

            panelScreen: modelData
        }
    }
}
