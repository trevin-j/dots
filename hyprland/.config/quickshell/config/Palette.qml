pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import "./" as ConfigFiles

QtObject {
    id: root

    readonly property bool ready: ConfigFiles.PaletteStore.ready
    readonly property var current: ConfigFiles.PaletteStore.current

    function color(role) {
        const value = current?.[role];
        if (value === undefined || value === null) {
            return "transparent";
        }
        return value;
    }

    readonly property color primary: current.primary || "#000000"
    readonly property color onPrimary: current.on_primary || "#ffffff"
    readonly property color primaryContainer: current.primary_container || "#000000"
    readonly property color onPrimaryContainer: current.on_primary_container || "#ffffff"

    readonly property color secondary: current.secondary || "#000000"
    readonly property color onSecondary: current.on_secondary || "#ffffff"
    readonly property color secondaryContainer: current.secondary_container || "#000000"
    readonly property color onSecondaryContainer: current.on_secondary_container || "#ffffff"

    readonly property color tertiary: current.tertiary || "#000000"
    readonly property color onTertiary: current.on_tertiary || "#ffffff"
    readonly property color tertiaryContainer: current.tertiary_container || "#000000"
    readonly property color onTertiaryContainer: current.on_tertiary_container || "#ffffff"

    readonly property color surface: current.surface || "#000000"
    readonly property color onSurface: current.on_surface || "#ffffff"
    readonly property color surfaceVariant: current.surface_variant || "#000000"
    readonly property color onSurfaceVariant: current.on_surface_variant || "#ffffff"

    readonly property color background: current.background || "#000000"
    readonly property color onBackground: current.on_background || "#ffffff"

    readonly property color outline: current.outline || "#ffffff"
    readonly property color outlineVariant: current.outline_variant || "#ffffff"

    readonly property color surfaceTint: current.surface_tint || primary
    readonly property color surfaceContainer: current.surface_container || surface
    readonly property color surfaceContainerLow: current.surface_container_low || surface
    readonly property color surfaceContainerHigh: current.surface_container_high || surface
    readonly property color surfaceContainerHighest: current.surface_container_highest || surface
    readonly property color surfaceContainerLowest: current.surface_container_lowest || surface
    readonly property color surfaceDim: current.surface_dim || surface
    readonly property color surfaceBright: current.surface_bright || surface

    readonly property color inverseSurface: current.inverse_surface || surface
    readonly property color inverseOnSurface: current.inverse_on_surface || onSurface
    readonly property color inversePrimary: current.inverse_primary || primary

    readonly property color error: current.error || "#b00020"
    readonly property color onError: current.on_error || "#ffffff"
    readonly property color errorContainer: current.error_container || error
    readonly property color onErrorContainer: current.on_error_container || onError

    readonly property color scrim: current.scrim || "#000000"
    readonly property color shadow: current.shadow || "#000000"
}
