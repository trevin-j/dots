# Config Schema Overview

This document defines live-reload configuration sources used by the shell.

## Files
- ConfigData.qml: immutable defaults bundled with the shell
- config.json: user overrides (hot-reloaded)
- palette.json: Material 3 role palette (light/dark variants, hot-reloaded)

## Config runtime model
- `ConfigStore.qml` watches `config.json` and parses overrides.
- `ConfigRuntime.qml` deep-merges overrides on top of `ConfigData.qml` defaults.
- `Config.qml` exposes effective values via `bar`, `appearance`, `motion`, `popouts`, `controlCenter`, `appDrawer`, `notifications`, and `whichKey`.

### config.json
```json
{
  "bar": {},
  "appearance": {},
  "motion": {},
  "popouts": {},
  "controlCenter": {},
  "appDrawer": {},
  "notifications": {},
  "whichKey": {}
}
```

Any subset of keys can be provided. Changes are reloaded at runtime.

### controlCenter (example)
```json
{
  "controlCenter": {
    "size": {
      "width": 420,
      "padding": 16,
      "spacing": 12,
      "traySpacing": 8,
      "trayItemHeight": 42,
      "toggleHeight": 58,
      "overshootPadding": 112
    },
    "nightLight": {
      "temperature": 3500
    },
    "transition": {
      "drawerOpenDelay": 0
    }
  }
}
```

### whichKey (example)
```json
{
  "whichKey": {
    "enabled": true,
    "leaderKey": "SUPER",
    "closeOnUnknown": true,
    "panel": {
      "width": 860,
      "padding": 18,
      "spacing": 12,
      "columns": 2,
      "columnSpacing": 12,
      "rowSpacing": 8,
      "itemHeight": 44,
      "iconSize": 18,
      "keySize": 13,
      "maxHeightRatio": 0.72
    },
    "binds": [
      {
        "keys": "<enter>",
        "description": "App drawer",
        "command": "qs ipc call appdrawer toggle",
        "icon": "apps"
      },
      {
        "keys": "p",
        "description": "Power",
        "command": "tlgui power",
        "icon": "power_settings_new"
      },
      {
        "keys": "wf",
        "description": "Fullscreen",
        "command": "hyprctl dispatch fullscreen",
        "icon": "fullscreen"
      }
    ]
  }
}
```

### appDrawer (example)
```json
{
  "appDrawer": {
    "size": {
      "columns": 10,
      "padding": 18,
      "spacing": 14,
      "tileHeight": 104,
      "iconSize": 38,
      "tileSpacing": 10,
      "searchHeight": 44,
      "searchHorizontalPadding": 18,
      "overshootPadding": 96
    },
    "behavior": {
      "drawerOpenDelay": 0,
      "searchDebounceMs": 35
    },
    "favorites": [
      "firefox.desktop",
      "org.wezfurlong.wezterm.desktop"
    ]
  }
}
```

- `size.rows` and `size.columns` define page size (`rows * columns`).
- Drawer height is derived from `rows`, tile sizing, search bar size, and paddings.
- The drawer body always spans the full screen width; only height is configurable.
- Favorites always sort first, then remaining apps are ranked by frecency.
- `behavior.pageSwipeThreshold` controls how far a swipe/scroll must travel before the drawer commits to the next page.
- `behavior.horizontalScrollSensitivity` scales horizontal wheel and touchpad scroll distance for page swiping.

### notifications (example)
```json
{
  "notifications": {
    "daemon": {
      "actionsSupported": true,
      "bodyMarkupSupported": false,
      "persistenceSupported": true
    },
    "popup": {
      "enabled": true,
      "maxVisible": 4,
      "width": 360,
      "marginTop": 48,
      "marginRight": 18,
      "defaultTimeoutMs": 6000,
      "criticalTimeoutMs": 0,
      "pauseOnHover": true,
      "showOnDnd": false,
      "showCriticalOnDnd": true
    },
    "history": {
      "maxEntries": 120,
      "retainTransient": false,
      "showReloaded": false
    },
    "panel": {
      "maxVisible": 8,
      "itemSpacing": 8,
      "itemMinHeight": 84,
      "showTimestamps": true,
      "allowClearAll": true
    }
  }
}
```

### popouts.volume.sound

`popouts.volume.sound` configures the feedback sound played when volume changes up or down.

- Disable playback: `"off"` (default). Also accepts `"none"` and `"disabled"`.
- Built-in sounds: `"warm"`, `"bouncy"`, `"chime"`
- Custom sound: absolute path to an audio file (for example `"/home/you/sounds/my-volume.wav"`)
- `popouts.volume.suppressWhenMicActive` (default `true`) skips playback while any app is actively recording from microphone (`pactl list source-outputs short`).

Example:

```json
{
  "popouts": {
    "volume": {
      "sound": "off",
      "suppressWhenMicActive": true
    }
  }
}
```

Custom path example:

```json
{
  "popouts": {
    "volume": {
      "sound": "/home/you/sounds/custom-volume.ogg"
    }
  }
}
```

## palette.json
```
{
  "version": 1,
  "mode": "dark",
  "light": {
    "primary": "#6750A4",
    "on_primary": "#FFFFFF",
    "primary_container": "#EADDFF",
    "on_primary_container": "#21005D",
    "secondary": "#625B71",
    "on_secondary": "#FFFFFF",
    "secondary_container": "#E8DEF8",
    "on_secondary_container": "#1D192B",
    "tertiary": "#7D5260",
    "on_tertiary": "#FFFFFF",
    "tertiary_container": "#FFD8E4",
    "on_tertiary_container": "#31111D",
    "surface": "#FEF7FF",
    "on_surface": "#1D1B20",
    "surface_variant": "#E7E0EC",
    "on_surface_variant": "#49454F",
    "background": "#FEF7FF",
    "on_background": "#1D1B20",
    "outline": "#79747E",
    "outline_variant": "#CAC4D0",
    "surface_tint": "#6750A4",
    "surface_container": "#F3EDF7",
    "surface_container_low": "#F7F2FA",
    "surface_container_high": "#ECE6F0",
    "surface_container_highest": "#E6E0E9",
    "surface_container_lowest": "#FFFFFF",
    "surface_dim": "#DED8E1",
    "surface_bright": "#FEF7FF",
    "inverse_surface": "#322F35",
    "inverse_on_surface": "#F5EFF7",
    "inverse_primary": "#D0BCFF",
    "error": "#B3261E",
    "on_error": "#FFFFFF",
    "error_container": "#F9DEDC",
    "on_error_container": "#410E0B",
    "scrim": "#000000",
    "shadow": "#000000",
    "source_color": "#6750A4",
    "primary_fixed": "#EADDFF",
    "primary_fixed_dim": "#D0BCFF",
    "on_primary_fixed": "#21005D",
    "on_primary_fixed_variant": "#4F378B",
    "secondary_fixed": "#E8DEF8",
    "secondary_fixed_dim": "#CCC2DC",
    "on_secondary_fixed": "#1D192B",
    "on_secondary_fixed_variant": "#4A4458",
    "tertiary_fixed": "#FFD8E4",
    "tertiary_fixed_dim": "#EFB8C8",
    "on_tertiary_fixed": "#31111D",
    "on_tertiary_fixed_variant": "#633B48"
  },
  "dark": {
    "primary": "#D0BCFF",
    "on_primary": "#381E72",
    "primary_container": "#4F378B",
    "on_primary_container": "#EADDFF",
    "secondary": "#CCC2DC",
    "on_secondary": "#332D41",
    "secondary_container": "#4A4458",
    "on_secondary_container": "#E8DEF8",
    "tertiary": "#EFB8C8",
    "on_tertiary": "#492532",
    "tertiary_container": "#633B48",
    "on_tertiary_container": "#FFD8E4",
    "surface": "#141218",
    "on_surface": "#E6E0E9",
    "surface_variant": "#49454F",
    "on_surface_variant": "#CAC4D0",
    "background": "#141218",
    "on_background": "#E6E0E9",
    "outline": "#938F99",
    "outline_variant": "#49454F",
    "surface_tint": "#D0BCFF",
    "surface_container": "#211F26",
    "surface_container_low": "#1D1B20",
    "surface_container_high": "#2B2930",
    "surface_container_highest": "#36343B",
    "surface_container_lowest": "#0F0D13",
    "surface_dim": "#141218",
    "surface_bright": "#3B383E",
    "inverse_surface": "#E6E0E9",
    "inverse_on_surface": "#322F35",
    "inverse_primary": "#6750A4",
    "error": "#F2B8B5",
    "on_error": "#601410",
    "error_container": "#8C1D18",
    "on_error_container": "#F9DEDC",
    "scrim": "#000000",
    "shadow": "#000000",
    "source_color": "#6750A4",
    "primary_fixed": "#EADDFF",
    "primary_fixed_dim": "#D0BCFF",
    "on_primary_fixed": "#21005D",
    "on_primary_fixed_variant": "#4F378B",
    "secondary_fixed": "#E8DEF8",
    "secondary_fixed_dim": "#CCC2DC",
    "on_secondary_fixed": "#1D192B",
    "on_secondary_fixed_variant": "#4A4458",
    "tertiary_fixed": "#FFD8E4",
    "tertiary_fixed_dim": "#EFB8C8",
    "on_tertiary_fixed": "#31111D",
    "on_tertiary_fixed_variant": "#633B48"
  }
}
```
