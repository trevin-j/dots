#!/usr/bin/env bash

process_upgrade_pkg() {
    prune_stale_commits

    while read -r pkg_file; do
        local pkg
        pkg=$(basename "$pkg_file")
        pkg=${pkg%.commit}
        echo "Upgrading $pkg..."
        perform_install_pkg "$pkg"
    done < <(find "$DATADIR" -type f -name '*.commit')
}

cmd_upgrade_help() {
    cat <<'EOF'
dotctl upgrade
  Reinstall all installed packages (no repo sync).
EOF
}
