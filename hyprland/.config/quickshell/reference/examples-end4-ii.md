# Example Notes: end-4 (ii)

## Structure
- Uses modules directory to group features (common, settings, shell, etc.).
- Settings app is a dedicated ApplicationWindow with custom navigation.
- Global state is stored in a Singleton (GlobalStates) for UI visibility flags.

## Global state
- GlobalStates tracks open/close for UI modules and feeds into visibility logic.
- GlobalShortcut is used for global keyboard state (e.g., super key).
- IpcHandler exposes simple controls (e.g., zoom in/out).

## Lessons
- Use a thin global state singleton for visibility toggles.
- Keep UI shell and settings UI separate to avoid coupling.
