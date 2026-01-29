# Hyprland Workspace Refresh

## Docs
- `Hyprland.rawEvent` emits for every event from the Hyprland event socket.
- Use `Hyprland.refreshWorkspaces()` to refresh workspace objects (needed for `lastIpcObject`).

## Example (Caelestia)
- On events like `workspace`, `openwindow`, `closewindow`, `movewindow`, `focusedmon`, Caelestia calls `Hyprland.refreshWorkspaces()`.
- This keeps `lastIpcObject` and workspace lists current.

## Recommended pattern
- Hook `Hyprland.rawEvent` and call `Hyprland.refreshWorkspaces()` for workspace/window changes.
- Rebuild any derived lists (`liveWorkspaces`) after refresh.
