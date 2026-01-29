pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import "./" as ConfigFiles

QtObject {
    id: root

    // Presets adapted from Caelestia shell.
    // License: https://github.com/caelestia-dots/shell/blob/main/LICENSE

    readonly property int shortDuration: ConfigFiles.Config.motion.durations?.short ?? 120
    readonly property int mediumDuration: ConfigFiles.Config.motion.durations?.medium ?? 200
    readonly property int longDuration: ConfigFiles.Config.motion.durations?.long ?? 320
    readonly property int smallDuration: ConfigFiles.Config.motion.durations?.small ?? 200
    readonly property int normalDuration: ConfigFiles.Config.motion.durations?.normal ?? 400
    readonly property int largeDuration: ConfigFiles.Config.motion.durations?.large ?? 600
    readonly property int extraLargeDuration: ConfigFiles.Config.motion.durations?.extraLarge ?? 1000
    readonly property int expressiveFastSpatialDuration: ConfigFiles.Config.motion.durations?.expressiveFastSpatial ?? 350
    readonly property int expressiveDefaultSpatialDuration: ConfigFiles.Config.motion.durations?.expressiveDefaultSpatial ?? 500
    readonly property int expressiveEffectsDuration: ConfigFiles.Config.motion.durations?.expressiveEffects ?? 200
    readonly property int shellDuration: ConfigFiles.Config.motion.durations?.shell ?? 260

    readonly property var standardCurve: ConfigFiles.Config.motion.curves?.standard ?? [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedCurve: ConfigFiles.Config.motion.curves?.emphasized ?? [0.05, 0.0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1.0, 1.0, 1.0]
    readonly property var emphasizedAccelCurve: ConfigFiles.Config.motion.curves?.emphasizedAccel ?? [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
    readonly property var emphasizedDecelCurve: ConfigFiles.Config.motion.curves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var standardAccelCurve: ConfigFiles.Config.motion.curves?.standardAccel ?? [0.3, 0.0, 1.0, 1.0, 1.0, 1.0]
    readonly property var standardDecelCurve: ConfigFiles.Config.motion.curves?.standardDecel ?? [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var expressiveFastSpatialCurve: ConfigFiles.Config.motion.curves?.expressiveFastSpatial ?? [0.42, 1.67, 0.21, 0.9, 1.0, 1.0]
    readonly property var expressiveDefaultSpatialCurve: ConfigFiles.Config.motion.curves?.expressiveDefaultSpatial ?? [0.38, 1.21, 0.22, 1.0, 1.0, 1.0]
    readonly property var expressiveEffectsCurve: ConfigFiles.Config.motion.curves?.expressiveEffects ?? [0.34, 0.8, 0.34, 1.0, 1.0, 1.0]
    readonly property var shellCurve: ConfigFiles.Config.motion.curves?.shell ?? expressiveDefaultSpatialCurve
}
