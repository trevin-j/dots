# AGENTS Guidance

## External docs and examples of good quickshell configurations
- Quickshell docs: https://quickshell.org/docs/v0.2.1/types/
- Quickshell tutorial: https://www.tonybtw.com/tutorial/quickshell/
- DankMaterialShell: https://github.com/AvengeMedia/DankMaterialShell
- end-4 quickshell config: https://github.com/end-4/dots-hyprland/tree/main/dots/.config/quickshell/ii
- zephyr: https://github.com/flickowoa/zephyr
- caelestia: https://github.com/caelestia-dots/shell

## Quality rules (mandatory)
- Use a single source of truth for config and theme; avoid scattered constants.
- Keep modules small and focused; prefer composition over inheritance.
- Use required properties on all reusable components.
- Keep UI purely declarative; route IO through services or dedicated helpers.
- Only add comments for non-obvious behavior or tricky edge cases.
- Prefer named animation curves and durations from Appearance/Anim singletons.
- Ensure all colors come from Material 3 roles; do not inline palette values.
- Maintain strict file organization (config, services, components, modules).
- Avoid cross-module imports that create circular dependencies.

## When implementing new features
- Start with config schema changes, then implement services, then UI components.
- Add docs at the top of components to state responsibilities and inputs.
- Reuse existing patterns for popouts, tray menus, and state layers.

## TOP-PRIORITY REQUIRED BEHAVIORS
- Must not call `qs` or `quickshell` unless explicitly told to do so. Even then, only one time.
- ALWAYS use settings that can be configured globally! Always use best programming practices and best QML programming behaviors!
