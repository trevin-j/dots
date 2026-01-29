# Workspace List Refresh

## Observed behavior
- `Hyprland.workspaces.values` can update without triggering bindings that depend on it.
- A manual refresh pattern using `Connections { target: Hyprland.workspaces; onValuesChanged: ... }` is safer.

## Guidance
- Keep live workspace lists in a mutable property (`property var liveWorkspaces`).
- Rebuild on `Hyprland.workspaces.values` changes.
- Filter special workspaces via `id < 0` or `name` starting with `special`.
