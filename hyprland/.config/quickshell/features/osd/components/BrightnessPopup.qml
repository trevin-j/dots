import QtQuick

import "../../../config" as Config
import "../../../services" as Services
import ".." as Osd

/*
  BrightnessPopup
  Brightness-specific binding around generic OSD slider popup.
*/
Osd.SliderPopup {
    id: root

    iconName: "brightness_6"
    level: Services.BrightnessService.level
    style: Config.Config.popouts?.brightness ?? ({})

    onLevelSet: value => {
        Services.BrightnessService.setLevel(value);
    }
}
