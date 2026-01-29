import QtQuick
import Quickshell

import "../../config" as Config
import "../../services" as Services
import "./"

/*!
  BrightnessPopupLayer
  Attaches brightness popup and watches brightness changes.
*/
Scope {
    id: root

    property bool shouldShowOsd: false
    property bool isInteracting: false
    property real brightnessLevel: Services.BrightnessService.level

    function showOsd() {
        root.shouldShowOsd = true;
        hideTimer.restart();
    }

    onBrightnessLevelChanged: showOsd()


    Connections {
        target: Services.BrightnessService

        function onLevelChanged() {
            root.showOsd();
        }
    }

    Timer {
        id: hideTimer

        interval: Config.Config.popouts?.brightness?.hideDelay ?? 1500
        repeat: false
        onTriggered: {
            if (root.isInteracting) {
                hideTimer.restart();
                return;
            }
            root.shouldShowOsd = false;
        }
    }

    BrightnessPopup {
        active: root.shouldShowOsd

        onInteractingChanged: {
            root.isInteracting = interacting;
            root.showOsd();
        }
    }

}
