#!/bin/env sh
tintterm '{{colors.primary.dark.hex}}' '{{colors.surface.dark.hex}}' '{{colors.on_surface.dark.hex}}' -q > ~/.cache/tintterm.json && python3 ~/.config/matugen/push_term_colors.py ~/.cache/tintterm.json
