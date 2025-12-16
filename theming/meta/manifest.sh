export requires=()
export require_aur="true"
export deps=(uv qt6ct-kde matugen swww)

post_stow() {
    uv tool install "$DOTDIR/theming/tintterm"
}
