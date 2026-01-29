# Centralized Config + Hot Reload

## JSON config pattern (Caelestia)
- FileView watches a JSON config file and triggers reload on file changes.
- JsonAdapter maps JSON to strongly-typed QML config objects.
- Config singleton re-exports sections using property aliases (appearance, bar, services, etc.).
- Debounced save path: changes are serialized with a short timer to avoid thrash.

## Reload behavior
- onFileChanged triggers reload, guarded by a recent save flag to avoid loop.
- onLoaded handles validation and optionally shows a toast or log entry.

## Config architecture
- Keep config schemas in dedicated QML files (BarConfig, AppearanceConfig, etc.).
- Provide a minimal user-facing JSON file for easy edits.
- Export Appearance and Theme as convenience singletons to keep UI references short.

## Takeaways
- JSON + FileView + JsonAdapter is a clean baseline for live configuration.
- Use required properties and explicit types to keep config integrity.
