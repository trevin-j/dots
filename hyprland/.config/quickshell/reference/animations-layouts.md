# Animating Layout Items

## Quickshell size/position rules
- Use implicit size for children; layouts assign actual size.
- Avoid binding width/height directly on items managed by layouts.
- Use `Layout.preferredWidth/Height` or `implicitWidth/Height` to influence layout sizing.

## QtQuick.Layouts guidance
- Items in layouts should set `Layout.preferredWidth`/`Layout.preferredHeight` for animated sizing.
- Direct width/height bindings can be overridden by the layout engine.
- `Layout.fillWidth/Height` controls whether items can stretch.

## Recommended pattern for animated pills
- Keep a stable `implicitHeight` and animate `Layout.preferredWidth` (or height in vertical bars).
- Use a dedicated animation component (Anim) with global curves/durations.
