# Hyprland Workspaces (Quickshell)

## Quickshell docs summary
- `Hyprland.workspaces` is an `ObjectModel` of `HyprlandWorkspace` objects, sorted by id.
- Named workspaces can have negative ids and appear before unnamed workspaces.
- `Hyprland.focusedWorkspace` is the globally focused workspace (may be null).
- `Hyprland.monitorFor(screen)` returns a `HyprlandMonitor` for a `ShellScreen`.
- `HyprlandWorkspace.activate()` triggers a workspace switch (equivalent to dispatching `workspace <name>`).
- `Hyprland.refreshWorkspaces()` can be called if data is stale or after IPC events.

## Caelestia patterns
- Central Hypr service exposes:
  - `activeWsId: focusedWorkspace?.id ?? 1`
  - `occupied` map built from `Hypr.workspaces.values` and `lastIpcObject.windows`.
- Workspace widget uses a group window (paged by `shown` count) and maps active index with `groupOffset`.
- Click actions use `Hypr.dispatch("workspace <id>")` and check for special workspace toggles.
- Uses `Hyprland.rawEvent` to refresh monitors/workspaces/toplevels after changes.

## end-4 patterns
- Compute monitor-scoped workspaces with:
  - `readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)`
  - `workspaceGroup` and `workspaceIndexInGroup` from `monitor.activeWorkspace?.id`.
- Update occupied list by watching `Hyprland.workspaces.values` changes.
- Workspace buttons compute `workspaceValue` and dispatch `workspace ${workspaceValue}`.

## Practical guidance
- Prefer model data that explicitly carries workspace ids (`modelData`) to avoid `index` scoping bugs.
- For per-monitor behavior, use `Hyprland.monitorFor(screen).activeWorkspace`.
- Occupied state should be derived from `Hyprland.workspaces.values`, e.g. `some(ws => ws.id === workspaceId)`.
- Use `Hyprland.refreshWorkspaces()` when reacting to IPC events if data seems stale.
