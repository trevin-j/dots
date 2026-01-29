# Example Notes: DankMaterialShell

## Theming
- Theme singleton holds Material 3 role palette and derived colors.
- Matugen integration generates palette from wallpaper or hex colors.
- Custom themes can be loaded from file and include variants (flavors/accents).
- FileView watches theme files and reloads on change.

## Animation system
- Shared curves are stored in Anims.qml and Theme.qml (emphasized, standard, expressive).
- Global animation speed influences duration tables for consistent feel.

## Widgets and modules
- Large set of reusable widgets (buttons, sliders, popouts, lists).
- Clear separation between Common (theme, data), Modules (features), Widgets (UI).

## Lessons
- Centralized theme roles allow consistent styling across modules.
- Explicit curve/duration tables make animations tunable and coherent.
- Keep utilities in Common to reduce duplication.
