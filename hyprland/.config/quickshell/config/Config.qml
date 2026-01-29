pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import "./" as ConfigFiles

QtObject {
    id: root

    readonly property bool ready: true

    readonly property var bar: ConfigFiles.ConfigData.bar
    readonly property var appearance: ConfigFiles.ConfigData.appearance
    readonly property var motion: ConfigFiles.ConfigData.motion
    readonly property var popouts: ConfigFiles.ConfigData.popouts
}
