# Hyprland Workspaces Examples

## Caelestia
- `modules/bar/components/workspaces/Workspaces.qml` uses a Hypr service wrapper:
  - `activeWsId` from `Hypr.focusedWorkspace?.id ?? 1`
  - `occupied` map from `Hypr.workspaces.values` and `lastIpcObject.windows`.
- Uses a `groupOffset` to paginate workspaces when `shown` < total.
- Click dispatch: `Hypr.dispatch(`workspace ${ws}`)`.
- Handles special workspaces by checking `monitor.activeWorkspace` and special workspace name.

## end-4 (ii)
- `monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)` for per-monitor.
- `workspaceGroup` + `workspaceIndexInGroup` for grouping.
- Occupied list updated on `Hyprland.workspaces.values` changes.
- Buttons dispatch `workspace ${workspaceValue}`.

## Notes for our build
- Avoid shadowing `index` in a `Repeater` delegate.
- Use explicit `workspaceValue` for `active`/`occupied`/`dispatch`.
- Consider `Hyprland.monitorFor(screen)` once per-monitor logic is needed.
