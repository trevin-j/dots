# Quickshell Refactor Checklist

This checklist defines the target architecture and migration order for the cohesive shell refactor.

## Goals
- Keep UI declarative and presentation-only.
- Route all IO and shell commands through services/adapters.
- Build reusable, composable controls to prevent duplication.
- Keep live JSON config reload active from day one.
- Preserve fluid, Caelestia-inspired motion language.

## Layering Rules
- `app/`: runtime shell composition entrypoint.
- `config/`: runtime config schema, defaults, live JSON stores, design token mapping.
- `design/`: reusable design tokens, primitives, and controls only.
- `features/`: user-facing modules composed from design controls and view-models.
- `services/`: platform and command integrations.

## Current scaffold (implemented)
- `config/ConfigRuntime.qml` merges defaults and `config/config.json` overrides.
- `features/osd/SliderPopup.qml` is the single reusable slider OSD surface.
- `features/quicksettings/` contains quick settings view-models and components.
- `features/bar/models/` contains workspace and active-window logic models.
- `features/bar/BarPanelFeature.qml` and `features/frame/FrameOverlayFeature.qml` host feature composition.
- `design/controls/*` and `design/primitives/*` host reusable controls and primitives.
- Legacy `modules/` and `components/` wrappers are fully removed.

## Migration Sequence
1. Runtime config and palette loaders drive all effective values.
2. Shared controls extracted for sliders, popups, and status chips.
3. OSD features migrate to shared controls.
4. Right status popover split into focused components.
5. Workspace and active-window logic moved into dedicated models.
6. Legacy modules and wrappers removed after feature parity validation.
7. Tests/lints introduced after architecture stabilizes.

## Definition of Done
- No feature file exceeds focused scope responsibilities.
- No command execution occurs in view files.
- New features consume tokenized design roles and motion presets.
- JSON config and palette changes hot-reload without restart.

## Enforced migration guardrails
- New reusable controls must be created in `design/controls` first.
- New feature state must be introduced in `features/*/vm` or `features/*/models` first.
- Imports from `modules/*` and top-level `components/*` are forbidden.
- View files should only orchestrate composition and bindings.

## Validation commands
- `scripts/check`
- `scripts/arch-guard`
- `qmllint $(rg --files -g '*.qml')`
- `scripts/test`
