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
- Maintain strict file organization (`app`, `config`, `design`, `features`, `services`).
- Avoid cross-feature imports that create circular dependencies.

## Runtime config + theme (mandatory)
- Live JSON reload is required from the start of every feature.
- Effective config must flow through `config/ConfigRuntime.qml` (defaults + JSON overrides).
- `config/config.json` is the user override source and must stay hot-reload safe.
- `config/palette.json` is the Material 3 role source and must stay hot-reload safe.
- Do not hardcode icon font families, spacing, durations, radii, or colors in feature files.

## Architecture boundaries (mandatory)
- `app/`: shell entry composition only.
- `design/`: reusable tokens, primitives, and controls only.
- `features/`: feature composition + view-model wiring only.
- `services/`: command execution, OS integration, and IO adapters.
- View files must not parse shell command output or orchestrate command pipelines.
- Feature logic should live in dedicated model/view-model components.
- Never import from `modules/` or `components/`; those paths are removed.

## Reusable component policy
- Favor generic controls (slider, toggle card, pills, action rows) over one-off feature widgets.
- Every reusable component must declare required inputs explicitly.
- Keep animation behavior tokenized through `Config.Motion`.
- Keep all text/icon typography tokenized through `Config.Appearance`.
- Source-of-truth reusable UI must live in `design/`; feature composition must live in `features/`.

## When implementing new features
- Start with config schema changes, then implement services/models, then UI components.
- Add docs at the top of components to state responsibilities and inputs.
- Reuse existing patterns for popouts, tray menus, and state layers.
- Every feature change must include test updates when logic behavior changes.
- Add tests under `tests/config`, `tests/features`, or `tests/services` based on ownership.

## TOP-PRIORITY REQUIRED BEHAVIORS
- Must not call `qs` or `quickshell` unless explicitly told to do so. Even then, only one time.
- ALWAYS use settings that can be configured globally! Always use best programming practices and best QML programming behaviors!

## Quality gate commands
- Run `scripts/arch-guard` before finalizing architecture-heavy changes.
- Run `qmllint $(rg --files -g '*.qml')` before finalizing implementation changes.
- Run `scripts/test` to execute baseline QML unit tests.
- Run `scripts/check` as the single full validation command.
