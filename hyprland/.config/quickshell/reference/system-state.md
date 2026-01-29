# Global State and Visibility

## end-4 GlobalStates pattern
- Singleton stores boolean flags for UI visibility.
- GlobalShortcut toggles a shared state (e.g., show workspace numbers).
- IpcHandler exposes small actions (zoom in/out) as IPC endpoints.

## Recommendations
- Use a minimal global state singleton for UI visibility and shortcuts.
- Keep state changes pure; route side effects to dedicated services.
- Keep all state changes observable for reactive UI updates.
