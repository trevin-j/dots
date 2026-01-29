# Quickshell Core Concepts

## Core window types
- PanelWindow: docks to a screen edge and reserves space (exclusive zone). Used for bars.
- FloatingWindow: free-floating window without reserved space.
- PopupWindow: transient popup anchored to a parent; use with anchors for menus and dialogs.
- ShellRoot/ShellScreen: root shell container and per-screen context. Used to spawn panels per monitor.

## Layout and composition
- QtQuick layout types (RowLayout, ColumnLayout, Repeater) are common for bar sections and widgets.
- DelegateChooser + Loader-based entries allow configurable bar sections.
- Anchors and implicit sizes are used to keep bar sizing responsive to content.

## IO and data integration
- Quickshell.Io.Process + SplitParser: run external commands and parse stdout lines for state.
- FileView + JsonAdapter: hot-reload JSON configuration and map to QML objects.
- SocketServer/IpcHandler: custom IPC for control and diagnostics.

## System services
- Quickshell.Services.SystemTray provides SystemTray and QsMenu* types for tray menus.
- Quickshell.Services.UPower exposes battery and power profile state.
- Quickshell.Services.Pipewire exposes audio and device state.
- Quickshell.Services.Notifications supports notification daemon implementation.

## Hyprland integration
- Quickshell.Hyprland exposes workspace, monitor, and active toplevel data.
- Hyprland.dispatch can run IPC commands (workspace switch, toggles, etc.).

## Practical bar primitives
- PanelWindow + anchors for positioning and reserved space.
- RowLayout/ColumnLayout and Repeater for workspace items and status icons.
- MouseArea or custom buttons for interactions.
