# AGENTS.md - Repository Guide for Coding Agents

This repository is a GNU Stow-based dotfiles monorepo.
It is mostly configuration and scripts (not a single app binary).

## What This Repo Contains

- `dotctl/`: install/management tooling (`dotctl`) for stowing packages and installing dependencies.
- `fonts/`: font assets (Nerd Fonts and related files) used by terminals/UI components.
- `foot/`: minimal `foot` terminal config.
- `hyprland/`: Hyprland WM config plus a substantial Quickshell codebase.
- `lf/`: `lf` file-manager config, custom previewer, trash/restore helpers.
- `opencode/`: local OpenCode CLI configuration (agents, commands, skills, AGENTS guidance).
- `theming/`: Matugen-driven theming pipeline, scripts, templates, and Python utilities.
- `tl/`: Trev's launcher scripts (`tl`, `tlgui`) using `fzf`, Wayland tools, and RBW integration.
- `zellij/`: Zellij KDL configuration.
- `zsh/`: interactive shell setup (`.zshrc`), plugin bootstrap, aliases, env wiring.
- `_package_template/`: template for creating new stow packages.

## Architecture Notes

- Top-level folders are installable stow packages unless prefixed with `_`.
- Each package usually has `meta/manifest.sh` with:
  - `requires`: package-level dependencies within this repo.
  - `pacman_deps` / `aur_deps`: system package dependencies.
  - legacy `deps` plus `require_aur` is still supported.
  - optional hooks: `pre_dl`, `pre_stow`, `post_stow`.
- `dotctl/.local/bin/dotctl` is the main package installer/orchestrator.
- No single global build tool exists for all packages.

## Git Workflow

This repository uses a simple git workflow: direct commits to the `master` branch are acceptable for this personal dotfiles repo. There is no need to create feature branches for routine updates. However, always ensure changes are minimal and focused.

## Build, Lint, and Test Commands

Run commands from repo root unless noted otherwise.

### Primary Validation Surface (Quickshell)

Working directory: `hyprland/.config/quickshell`

- Full check (architecture + lint + tests):
  - `scripts/check`
- Architecture checks only:
  - `scripts/arch-guard`
- QML lint only:
  - `qmllint $(rg --files -g '*.qml')`
- All QML tests:
  - `scripts/test`
- Run a single QML test file (important):
  - `QT_QPA_PLATFORM=offscreen qmltestrunner -input tests/services/tst_notification_logic.qml -o -,txt`
- Run one test function pattern from a file (QtTest):
  - `QT_QPA_PLATFORM=offscreen qmltestrunner -input tests/services/tst_notification_logic.qml -functions test_shouldShowPopup -o -,txt`

### Python Utility: materialized-web

Working directory: `theming/.config/matugen/materialized-web`

- Install/sync dependencies:
  - `uv sync`
- Run dev server:
  - `uv run app.py`
- Run tests (if/when tests exist):
  - `uv run pytest`
- Run a single test (important):
  - `uv run pytest tests/test_compiler.py::test_compile_css_for_url`

### Python Utility: tintterm

Working directory: `theming/tintterm`

- Install as a tool (repo pattern used in manifests):
  - `uv tool install .`
- Run CLI locally:
  - `uv run tintterm '#89b4fa' '#1e1e2e' '#cdd6f4' -q`

### Dotfiles Package Management

- Install one package:
  - `dotctl/.local/bin/dotctl install <package>`
- Install all packages:
  - `dotctl/.local/bin/dotctl install all`
- Upgrade installed packages from git commits:
  - `dotctl/.local/bin/dotctl upgrade`
- List installed vs not installed:
  - `dotctl/.local/bin/dotctl ls`

## Testing Guidance

- Prioritize testing changes where logic exists:
  - Quickshell parsers/services/config merge logic.
  - Python logic in `materialized-web` and theming helpers.
- For config-only edits (e.g., static JSON/CSS/KDL), run nearest relevant lints or smoke checks.
- Keep tests deterministic; avoid network dependence in unit tests.

## Code Style and Conventions

Follow existing style in each subproject; do not force a single formatter across all packages.

### Shell Scripts (`bash`/`sh`)

- Prefer `#!/usr/bin/env bash` for Bash scripts; `sh` only when POSIX intent is explicit.
- Use `set -euo pipefail` in Bash scripts that orchestrate state.
- Use `snake_case` function names (`process_install_pkg`, `load_times`).
- Quote variable expansions unless deliberate word splitting is needed.
- Use `local` inside functions for scoped variables.
- Check external commands with `command -v <cmd> >/dev/null 2>&1`.
- Emit user-facing errors to stderr (`>&2`) and non-zero exit codes.
- Prefer explicit `case` blocks for command dispatch.
- Keep side effects in clearly named functions; avoid giant inline pipelines when possible.

### Python

- Follow PEP 8 and keep imports grouped: stdlib, third-party, local.
- Prefer `pathlib.Path` over raw path strings for file IO.
- Use type hints for function signatures and return values (as seen in `materialized-web`).
- Prefer small pure helpers for parsing/transform logic.
- Handle malformed external inputs defensively.
- Raise/return clear errors for API boundaries; avoid silent broad `except` unless intentionally best-effort (document why).
- Keep constants uppercase (`BASE_COLORS`, `PAIRS`).

### QML / Quickshell

- Preserve architecture boundaries:
  - `app/` composition only.
  - `config/` runtime config, schema, palette, motion tokens.
  - `design/` reusable UI primitives/controls.
  - `features/` feature composition and view-model wiring.
  - `services/` IO, command execution, adapters, parsers.
- Keep UI declarative; route IO and process interactions through services.
- Prefer required properties on reusable components.
- Keep theme values tokenized via config/palette, not hardcoded ad hoc.
- Use `camelCase` for QML properties/functions, `PascalCase` for component files.
- Add/update QML tests when parser/service behavior changes.

### JSON/JSONC/CSS/KDL/Conf

- Keep existing indentation and key ordering style for the file you edit.
- Avoid reformat-only churn unless specifically requested.
- In JSONC, keep comments practical and close to the setting they describe.
- In CSS, prefer readable grouped selectors and avoid unnecessary specificity escalation.

## Naming and Organization

- Keep package-local naming conventions intact.
- New scripts in package bins should use descriptive verbs (`preview-*`, `update-*`, `restore-*`).
- New tests should follow current patterns:
  - QML: `tests/**/tst_*.qml`
  - Python: `tests/test_*.py`

## Error Handling Rules

- Fail fast for required prerequisites (missing command, missing file, invalid args).
- For optional best-effort behavior (e.g., pushing terminal colors to all PTYs), swallow non-critical per-target failures and continue.
- Log enough context to diagnose failures in long-running scripts.

## Dependency Management Rules

- Prefer CLI package managers instead of manual file edits for dependency changes.
- Examples:
  - Python: `uv add <dep>`
  - Node: `npm add <dep>`
  - Rust: `cargo add <dep>`
- Do not pin versions unless required by the task or existing project constraints.

## Practical Agent Workflow

1. Identify affected package(s) first.
2. Read that package's `meta/manifest.sh` and local docs/AGENTS guidance.
3. Make minimal, package-scoped edits.
4. Run nearest validation commands (especially Quickshell `scripts/check` for shell UI changes).
5. Report commands run and results succinctly.
