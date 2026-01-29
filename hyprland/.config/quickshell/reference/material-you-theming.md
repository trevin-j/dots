# Material You Theming (Material 3)

## Core idea
- Maintain a single palette map with modern Material 3 roles (primary, on_primary, surface_container, outline_variant, etc.).
- Theme updates should be reactive: palette changes propagate to all widgets.

## DankMaterialShell pattern
- Dynamic theme uses matugen output to populate M3 roles.
- Custom theme and stock themes merge into the same role map.
- Theme singleton exposes palette roles and derived colors (hover, pressed, alphas).
- Matugen mapping includes roles like primary_fixed, inverse_surface, surface_container_highest.

## Zephyr pattern
- Colors.qml is a Singleton storing Material 3 roles.
- Process runs matugen and fills Colors properties from JSON output.
- After load, other processes generate configs for terminal and compositor.

## Recommendations for new shell
- Use a JSON palette file with M3 role names. Keep keys consistent with matugen naming.
- Build a Theme singleton with computed values (hover, pressed, alpha blends).
- Treat palette changes as the only source of UI color changes.
- Include light/dark variants even if currently using only one.
