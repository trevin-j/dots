# Animations and Motion

## Motion system principles
- Define named durations and bezier curves in a central Appearance/Anim singleton.
- Use Behaviors and Transitions consistently; avoid ad-hoc animation values.
- Favor expressive curves for spatial movement and standard curves for opacity.

## DankMaterialShell patterns
- Curves stored as bezier arrays: emphasized, emphasizedAccel, emphasizedDecel, standard.
- Expressive curves include expressiveFastSpatial and expressiveDefaultSpatial.
- Animation duration scales off a base speed for global tuning.

## Caelestia patterns
- Anim component is used as a shorthand for NumberAnimation with shared curves/durations.
- Bar wrapper uses animated width transitions when showing/hiding.
- Popout wrapper animates x/y/implicit sizes with shared easing curves.

## Recommendations
- Provide an Anim component that wraps NumberAnimation with default easing/duration.
- Use explicit states and transitions for show/hide instead of manual animations.
- Keep animation values in config for tuning without code changes.
