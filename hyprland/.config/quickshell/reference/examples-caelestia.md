# Example Notes: Caelestia

## Architecture
- Config is split into many QML config objects, loaded from a JSON file via FileView + JsonAdapter.
- Appearance singleton exposes derived properties from config for ease of use.
- Bar is modular: BarWrapper handles visibility/size; Bar provides entries with DelegateChooser.

## Bar organization
- Config.bar.entries defines layout, each item is loaded via WrappedLoader.
- BarWrapper animates the bar width based on hover/visibility.
- Bar handles scroll actions and popout routing based on hit-testing.

## Widgets
- Active window title rotates text for vertical bars and uses TextMetrics for eliding.
- Workspaces use `activeWsId` + `occupied` map and group offsets for pagination.
- Status icons aggregate audio/network/battery/bluetooth/kb-lock state.
- Custom components (StyledText, StyledRect, MaterialIcon) encapsulate style.

## Popouts
- Popouts are routed by name; Wrapper handles focus and animation.
- Detached popouts use HyprlandFocusGrab and WlrLayershell keyboard focus.
- Tray menus are handled with StackView and QsMenuOpener.
