export requires=()
export pacman_deps=(uv qt6ct-kde swww python-pywalfox)
export aur_deps=(matugen-git)

post_stow() {
    pywalfox install || true
}
