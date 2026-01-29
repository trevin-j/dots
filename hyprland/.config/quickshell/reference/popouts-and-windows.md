# Popouts and Popup Windows

## Caelestia popout wrapper pattern
- Wrapper manages current popout name and active state.
- It calculates implicit sizes from the active popout and animates x/y/width/height.
- Focus is captured while detached (HyprlandFocusGrab) and keyboard focus set to OnDemand.
- Popouts are Loaders with state-driven activation and opacity/scale transitions.

## Content organization
- Content.qml uses a Popout Loader component with name-based activation.
- Popouts are keyed to names like "network", "battery", "traymenuN".
- Content handles tray menu popouts with a Repeater that rebuilds when active.

## Tray menu pattern
- TrayMenu.qml uses StackView with zero-duration transitions for menu navigation.
- QsMenuOpener exposes menu entries; SubMenu renders items and handles child menus.
- Use StyledRect/StateLayer for hover/click feedback and Material icons.

## Recommendations
- Keep a single popout orchestrator for focus management and sizing.
- Use a name-based routing model for popout selection.
- Animate popout scaling and opacity for entry/exit, separate from position animation.
