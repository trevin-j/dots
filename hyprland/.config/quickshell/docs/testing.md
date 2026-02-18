# Testing and Linting

## Required commands
- Full validation: `scripts/check`
- Architecture guard only: `scripts/arch-guard`
- Lint only: `qmllint -U $(rg --files -g '*.qml')`
- Tests only: `scripts/test`

## Test layout
- `tests/config/`: config merge/fallback behavior.
- `tests/features/`: feature view-model and parsing behavior.
- `tests/services/`: service parser and state transition behavior.

## Contribution rules
- Add or update tests whenever feature logic or service parsing changes.
- Keep tests deterministic and local-only (no external network dependencies).
- Prefer testing pure parser/logic modules (`*.js`) used by QML components.
