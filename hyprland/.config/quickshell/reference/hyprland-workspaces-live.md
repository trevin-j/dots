# Live Workspace Filtering

## Findings
- `Hyprland.workspaces` is the authoritative list of workspaces currently known to Hyprland.
- Examples use `lastIpcObject.windows` from `HyprlandWorkspace` to detect occupancy.
- Named workspaces may use negative ids; rely on the `name` field for display.
- Special workspaces are not part of the normal numeric flow and are handled separately (e.g., by reading `monitor.activeWorkspace` and its special workspace name).

## Suggested filters
- Live workspaces: `Hyprland.workspaces.values`.
- Occupied workspaces: `workspace.lastIpcObject?.windows > 0`.
- Named workspaces: `workspace.name` not equal to workspace id as string.
- Special workspaces: filter out `workspace.name` that starts with "special" or check `workspace.id < 0`.
