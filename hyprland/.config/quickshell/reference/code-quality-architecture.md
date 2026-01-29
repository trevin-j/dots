# Code Quality and Architecture Rules

## Core principles
- Single source of truth for theme, config, and services.
- Separate concerns: config/schema, services/state, UI components, feature modules.
- Use required properties on QML components to enforce contracts.
- Keep components small; avoid one-file mega components.

## Maintainability
- Use descriptive component names and keep file structure consistent.
- Avoid hard-coded values in widgets; route through Appearance/Config singletons.
- Prefer explicit state machines (states + transitions) over implicit logic.

## Documentation
- Add comments only for non-obvious logic or tricky side effects.
- Document public properties and expected data shape in component headers.
- Keep any inline documentation short and action-oriented.

## Testing and safety
- Avoid side effects in component constructors (Component.onCompleted).
- Use dedicated services for IO and shell commands.
- Use debounced updates for config writes and expensive IO.

## Styling
- Centralize sizes, spacing, radius, fonts in Appearance.
- Use Material 3 role names consistently.
- Expose animation durations and curves via config for consistent motion.
