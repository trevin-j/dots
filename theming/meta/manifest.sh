export requires=()
export require_aur="true"
export deps=(uv qt6ct-kde matugen-git swww python-pywalfox)

post_stow() {
    pywalfox install || true
}
