pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import "./" as ConfigFiles
import "ConfigMerge.js" as Merge

QtObject {
    id: root

    readonly property var defaults: ConfigFiles.ConfigData
    readonly property var overrides: ConfigFiles.ConfigStore.overrides
    readonly property bool ready: ConfigFiles.ConfigStore.ready

    readonly property var merged: Merge.mergeWithDefaults(defaults, overrides)

    readonly property var bar: merged.bar
    readonly property var appearance: merged.appearance
    readonly property var motion: merged.motion
    readonly property var popouts: merged.popouts
    readonly property var controlCenter: merged.controlCenter
    readonly property var appDrawer: merged.appDrawer
    readonly property var bitwardenPicker: merged.bitwardenPicker
    readonly property var clipboardHistory: merged.clipboardHistory
    readonly property var emojiPicker: merged.emojiPicker
    readonly property var nerdFontPicker: merged.nerdFontPicker
    readonly property var notifications: merged.notifications
    readonly property var whichKey: merged.whichKey
}
