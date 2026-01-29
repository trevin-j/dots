# Widget Patterns

## Common building blocks
- StyledText/StyledRect/MaterialIcon are commonly used wrapper components.
- StateLayer is used to implement hover/pressed/disabled feedback.
- Components should be theme-aware via Colors/Appearance singletons.

## List and Repeater patterns
- Use ScriptModel for filtered/sorted lists (e.g., tray items, networks).
- Use Loader with active/visible states to save resources.

## Icon strategies
- Material icons are often driven by system state (battery level, audio volume).
- Keep icon selection in helper functions to avoid duplicated logic.
