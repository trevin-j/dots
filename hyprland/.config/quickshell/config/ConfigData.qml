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
        searchMenu: ({
            enabled: true
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
            sound: "off",
            suppressWhenMicActive: true,
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
        wallpaper: ({
            directory: "~/Pictures/wallpapers",
            panelWidth: 460,
            overshootPadding: 64,
            itemSpacing: 12,
            itemHeight: 170,
            selectedItemHeight: 264,
            thumbnailWidth: 320,
            selectedThumbnailWidth: 410,
            gapNearSelected: 8,
            gapRegular: 2,
            extensions: [".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"],
            preloadItems: 6
        }),
        transition: ({
            drawerOpenDelay: 0
        }),
        bitwarden: ({
            visible: true
        })
    })

    readonly property var appDrawer: ({
        size: ({
            width: 482,
            rows: 3,
            columns: 5,
            padding: 24,
            spacing: 24,
            tileHeight: 104,
            iconSize: 38,
            tileSpacing: 20,
            searchHeight: 54,
            searchHorizontalPadding: 18,
            overshootPadding: 64
        }),
        behavior: ({
            drawerOpenDelay: 0,
            searchDebounceMs: 35
        }),
        favorites: []
    })

    readonly property var bitwardenPicker: ({
        size: ({
            itemHeight: 64,
            itemSpacing: 8,
            iconSize: 18
        }),
        setup: ({
            width: 420,
            padding: 18,
            spacing: 12,
            inputHeight: 42,
            buttonHeight: 40
        })
    })

    readonly property var clipboardHistory: ({
        size: ({
            itemHeight: 60,
            itemSpacing: 8,
            iconSize: 18
        })
    })

    readonly property var emojiPicker: ({
        grid: ({
            columns: 6,
            tileHeight: 76,
            tileSpacing: 12,
            glyphSize: 30,
            fontFamily: ""
        })
    })

    readonly property var nerdFontPicker: ({
        grid: ({
            columns: 6,
            tileHeight: 76,
            tileSpacing: 12,
            glyphSize: 30,
            fontFamily: "Hack Nerd Font Mono"
        })
    })

    readonly property var notifications: ({
        daemon: ({
            keepOnReload: true,
            actionsSupported: true,
            actionIconsSupported: false,
            bodySupported: true,
            bodyMarkupSupported: false,
            bodyHyperlinksSupported: false,
            bodyImagesSupported: false,
            imageSupported: true,
            persistenceSupported: true,
            inlineReplySupported: false,
            extraHints: []
        }),
        popup: ({
            enabled: true,
            maxVisible: 4,
            width: 360,
            spacing: 10,
            slideDistance: 30,
            marginTop: 24,
            marginRight: 18,
            itemPadding: 12,
            iconSize: 22,
            defaultTimeoutMs: 6000,
            criticalTimeoutMs: 0,
            actionableAutoCloseMs: 600000,
            ignoreTimeoutFromClients: false,
            pauseOnHover: true,
            showOnDnd: false,
            showCriticalOnDnd: true
        }),
        history: ({
            maxEntries: 120,
            retainTransient: false,
            showReloaded: false
        }),
        panel: ({
            maxVisible: 8,
            itemSpacing: 8,
            itemMinHeight: 84,
            showTimestamps: true,
            allowClearAll: true
        })
    })

    readonly property var whichKey: ({
        enabled: true,
        leaderKey: "SUPER",
        closeOnUnknown: true,
        panel: ({
            width: 860,
            padding: 18,
            spacing: 12,
            columns: 2,
            columnSpacing: 12,
            rowSpacing: 8,
            itemHeight: 44,
            iconSize: 18,
            keySize: 13,
            maxHeightRatio: 0.72,
            offset: 6,
            slideDistance: 20
        }),
        binds: [
            ({ keys: "<enter>", description: "App drawer", command: "qs ipc call appdrawer toggle", icon: "apps" }),
            ({ keys: "w", description: "Window", icon: "web_asset" }),
            ({ keys: "wf", description: "Fullscreen", command: "hyprctl dispatch fullscreen", icon: "fullscreen" }),
            ({ keys: "wv", description: "Toggle floating", command: "hyprctl dispatch togglefloating", icon: "picture_in_picture_alt" }),
            ({ keys: "ws", description: "Toggle pseudo", command: "hyprctl dispatch pseudo", icon: "splitscreen" }),
            ({ keys: "wp", description: "Pin window", command: "hyprctl dispatch pin", icon: "push_pin" }),
            ({ keys: "wl", description: "Toggle split", command: "hyprctl dispatch togglesplit", icon: "call_split" }),
            ({ keys: "wr", description: "Move to root", command: "hyprctl dispatch layoutmsg movetoroot", icon: "account_tree" }),
            ({ keys: "ww", description: "Swap split", command: "hyprctl dispatch layoutmsg swapsplit", icon: "swap_horiz" }),
            ({ keys: "u", description: "Utilities", icon: "build" }),
            ({ keys: "ud", description: "Dictation", icon: "keyboard_voice" }),
            ({ keys: "uds", description: "Start dictation", command: "nerd-dictation begin --simulate-input-tool=WTYPE", icon: "keyboard_voice" }),
            ({ keys: "ude", description: "End dictation", command: "nerd-dictation end", icon: "mic_off" }),
            ({ keys: "uc", description: "Color picker", command: "hyprpicker | wl-copy -n", icon: "colorize" }),
            ({ keys: "c", description: "Control center", command: "qs ipc call controlcenter toggle", icon: "settings" }),
            ({ keys: "r", description: "Rename workspace", command: "qs ipc call workspace openRenamePanel", icon: "edit" }),
            ({ keys: "s", description: "Search", icon: "search" }),
            ({ keys: "sp", description: "Passwords", command: "qs ipc call bitwarden togglePassword", icon: "password" }),
            ({ keys: "st", description: "TOTP codes", command: "qs ipc call bitwarden toggleTotp", icon: "pin" }),
            ({ keys: "su", description: "Usernames", command: "qs ipc call bitwarden toggleUsername", icon: "person" }),
            ({ keys: "sc", description: "Clipboard history", command: "qs ipc call clipboardhistory toggle", icon: "content_paste" }),
            ({ keys: "se", description: "Emoji picker", command: "qs ipc call emoji toggle", icon: "emoji_emotions" }),
            ({ keys: "sn", description: "Nerd font picker", command: "qs ipc call nerdfont toggle", icon: "font_download" })
        ]
    })
}
