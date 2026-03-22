#!/usr/bin/env bash

process_update_pkg() {
    echo "Syncing repo..."
    if ! sync_repo; then
        die "Sync failed. Aborting update."
    fi

    echo
    process_upgrade_pkg
}

cmd_update_help() {
    cat <<'EOF'
dotctl update
  Sync the repo then upgrade installed packages.
EOF
}
