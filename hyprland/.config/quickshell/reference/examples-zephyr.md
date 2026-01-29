# Example Notes: Zephyr

## Theme flow
- Colors.qml stores Material 3 roles as a singleton.
- Process runs matugen and updates Colors properties with JSON output.
- A video wallpaper path is handled by extracting a frame for matugen.

## Shell structure
- Main.qml builds the shell and a bar window with left/right items arrays.
- Config.qml exposes design constants (bar size, workspace spacing, clock settings).

## Lessons
- Simple singleton config can drive layout and color usage.
- Matugen output can be applied directly to a Colors singleton.
