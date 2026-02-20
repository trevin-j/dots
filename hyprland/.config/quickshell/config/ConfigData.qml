pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

// Centralized shell configuration values.
QtObject {
    readonly property var bar: ({
        position: "top",
        size: ({
            thickness: 36,
            padding: 6,
            margin: 0,
            marginTop: 0,
            marginBottom: 0,
            marginSide: 0,
            spacing: 8
        }),
        behavior: ({
            exclusiveZone: true,
            scrollToSwitchWorkspaces: true
        }),
        layout: ({
            left: ["workspaces"],
            center: ["activeWindow"],
            right: ["statusGroup", "date"]
        })
    })

    readonly property var appearance: ({
        font: ({
            family: "Roboto",
            iconFamily: "Material Symbols Rounded",
            size: ({
                small: 11,
                medium: 13,
                large: 16
            }),
            weight: 400
        }),
        radius: ({
            small: 6,
            medium: 12,
            large: 18
        }),
        frame: ({
            borderThickness: 2,
            borderRounding: 18,
            bubbleRounding: 14,
            bubblePadding: 6,
            reservedBarExtent: null,
            frameColorRole: "outline_variant",
            maskThresholdMin: 0.5,
            maskSpreadAtMin: 1.0
        }),
        cutoutBlack: "#000000",
        shadow: ({
            enabled: true,
            opacity: 0.26,
            blur: 30,
            offsetY: 8
        })
    })

    readonly property var motion: ({
        durations: ({
            short: 120,
            medium: 200,
            long: 320,
            small: 200,
            normal: 400,
            large: 600,
            extraLarge: 1000,
            expressiveFastSpatial: 350,
            expressiveDefaultSpatial: 500,
            expressiveEffects: 200,
            shell: 260
        }),
        curves: ({
            standard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0],
            emphasized: [0.05, 0.0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1.0, 1.0, 1.0],
            emphasizedAccel: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0],
            emphasizedDecel: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0],
            standardAccel: [0.3, 0.0, 1.0, 1.0, 1.0, 1.0],
            standardDecel: [0.0, 0.0, 0.0, 1.0, 1.0, 1.0],
            expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1.0, 1.0],
            expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.0, 1.0, 1.0],
            expressiveEffects: [0.34, 0.8, 0.34, 1.0, 1.0, 1.0],
            shell: [0.38, 1.21, 0.22, 1.0, 1.0, 1.0]
        })
    })

    readonly property var popouts: ({
        spacing: 8,
        offset: 6,
        volume: ({
            width: 280,
            padding: 16,
            spacing: 12,
            iconSize: 18,
            trackHeight: 6,
            thumbSize: 16,
            hideDelay: 1500,
            slideDistance: 20,
            offset: 6
        }),
        brightness: ({
            width: 280,
            padding: 16,
            spacing: 12,
            iconSize: 18,
            trackHeight: 6,
            thumbSize: 16,
            hideDelay: 1500,
            slideDistance: 20,
            offset: 6,
            device: "intel_backlight"
        })
    })

    readonly property var controlCenter: ({
        size: ({
            width: 420,
            padding: 16,
            spacing: 12,
            traySpacing: 8,
            trayItemHeight: 42,
            toggleHeight: 58,
            overshootPadding: 112
        }),
        nightLight: ({
            temperature: 3500
        }),
        transition: ({
            drawerOpenDelay: 0
        })
    })
}
