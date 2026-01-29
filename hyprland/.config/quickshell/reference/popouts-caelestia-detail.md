# Popout Details (Caelestia)

## Wrapper.qml
- Wrapper is an Item that manages popout visibility, size, and focus.
- Uses currentName/currentCenter/hasCurrent to route active popouts.
- Detached popouts set HyprlandFocusGrab and WlrLayershell keyboard focus.
- Animates x, y, implicitWidth, and implicitHeight with shared curves.

## Content.qml
- A Popout Loader component is activated when its name matches currentName.
- Popouts animate via opacity + scale transitions and use activation states.
- Tray menu popouts are created with a Repeater and refreshed when opened.

## TrayMenu.qml
- Uses StackView with transitions disabled for snappy menu navigation.
- QsMenuOpener provides menu entries for QsMenuHandle.
- SubMenu items are built from StyledRect + StateLayer; entries trigger QsMenuEntry actions.

## Network.qml
- Lists wireless networks with strength ordering and state-based styles.
- Connect/disconnect actions are handled via Nmcli service.
- Shows a password dialog popout for secure networks.

## Battery.qml
- Shows device state, time to empty/full, and power profile toggle.
- Power profile switching uses a sliding indicator with AnchorAnimation.
