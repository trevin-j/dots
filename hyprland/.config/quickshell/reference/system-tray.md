# System Tray Implementation

## Quickshell services
- Quickshell.Services.SystemTray provides SystemTray and SystemTrayItem.
- QsMenuHandle, QsMenuEntry, and QsMenuOpener support tray menus.

## Caelestia pattern
- Status icons are separate from tray icons; tray items render as a compact list.
- Tray menu is a StackView that loads submenus via QsMenuOpener entries.
- Menu items support separators and disabled states, using StyledRect + StateLayer.

## Recommendations
- Separate tray icon list from tray menus; use a dedicated popout window for menus.
- Rebuild tray menu popouts on open to ensure fresh state.
- Provide icon substitution rules for improved look consistency.
