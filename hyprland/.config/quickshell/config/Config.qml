pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import "./" as ConfigFiles

QtObject {
    id: root

    readonly property bool ready: ConfigFiles.ConfigRuntime.ready

    readonly property var bar: ConfigFiles.ConfigRuntime.bar
    readonly property var appearance: ConfigFiles.ConfigRuntime.appearance
    readonly property var motion: ConfigFiles.ConfigRuntime.motion
    readonly property var popouts: ConfigFiles.ConfigRuntime.popouts
    readonly property var controlCenter: ConfigFiles.ConfigRuntime.controlCenter
}
