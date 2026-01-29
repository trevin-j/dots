# Tutorial Notes (Tony BTW)

## Basic bar
- PanelWindow docks to screen edges and reserves space.
- anchors.top/left/right with implicitHeight is the simplest bar layout.
- RowLayout + Item spacer pushes sections to left/right.

## Workspaces (Hyprland)
- Hyprland.workspaces provides workspace list; Hyprland.focusedWorkspace for active.
- Repeater with model count is a simple workspace list.
- MouseArea with Hyprland.dispatch handles switching.

## Processes and timers
- Process + SplitParser reads command output and updates state.
- Timer is used for periodic refresh.
- QML Text with its own Timer is adequate for a clock.
