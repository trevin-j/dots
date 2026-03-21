#!/usr/bin/env bash

process_update_pkg() {
    echo "Syncing repo..."
    if ! sync_repo; then
        die "Sync failed. Aborting update."
    fi

    echo
    echo "Upgrading installed packages..."
    while read -r pkg_file; do
        local pkg
        pkg=$(basename "$pkg_file")
        pkg=${pkg%.commit}
        echo "Upgrading $pkg..."
        perform_install_pkg "$pkg"
    done < <(find "$DATADIR" -type f -name '*.commit')
}

cmd_update_help() {
    cat <<'EOF'
dotctl update
  Sync the repo then upgrade installed packages.
EOF
}
