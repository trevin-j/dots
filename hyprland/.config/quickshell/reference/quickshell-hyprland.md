# Hyprland Integration Notes

## Workspace patterns
- `Hyprland.workspaces` is an ObjectModel sorted by id; named workspaces have negative ids.
- `Hyprland.focusedWorkspace` is the focused workspace (may be null).
- `HyprlandWorkspace.activate()` is equivalent to `Hyprland.dispatch("workspace <name>")`.
- `Hyprland.dispatch("workspace <n>")` is a direct switch action.
- Per-monitor handling can use `Hyprland.monitorFor(screen)` or `Hyprland.focusedMonitor`.
- Use `Hyprland.refreshWorkspaces()` if workspace state appears stale.

## Active window
- Hyprland.activeToplevel provides title/class for current app title and icon lookup.
- Use TextMetrics for eliding long titles and animated transitions between titles.

## Input and focus
- HyprlandFocusGrab can keep keyboard focus inside popouts while they are active.
- WlrLayershell keyboard focus can be set to OnDemand for specific popouts.

## Locks and status
- Hyprland exposes capsLock and numLock for status icons.
- Hyprland active workspace and special workspace handling can drive badge/indicator state.
