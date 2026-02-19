import QtQuick
import Quickshell.Services.Pipewire

import "../../../config" as Config
import ".." as Osd

/*
  VolumePopup
  Volume-specific binding around generic OSD slider popup.
*/
Osd.SliderPopup {
    id: root

    readonly property real volumeLevel: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    readonly property bool volumeMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    iconName: {
        if (volumeMuted || volumeLevel <= 0) {
            return "volume_off";
        }
        if (volumeLevel < 0.3) {
            return "volume_mute";
        }
        if (volumeLevel < 0.7) {
            return "volume_down";
        }
        return "volume_up";
    }
    level: volumeMuted ? 0 : volumeLevel
    style: Config.Config.popouts?.volume ?? ({})

    onLevelSet: value => {
        const audio = Pipewire.defaultAudioSink?.audio;
        if (!audio) {
            return;
        }
        audio.volume = value;
        if (value > 0 && audio.muted) {
            audio.muted = false;
        }
    }
}
