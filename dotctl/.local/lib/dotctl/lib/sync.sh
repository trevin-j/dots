#!/usr/bin/env bash

sync_repo() {
    if ! git -C "$DOTDIR" diff-index --quiet HEAD -- 2>/dev/null; then
        echo "Uncommitted changes detected in $DOTDIR." >&2
        echo "Commit or stash your changes before syncing." >&2
        echo "To stash: cd $DOTDIR && git stash" >&2
        echo "To restore: cd $DOTDIR && git stash pop" >&2
        return 1
    fi

    if ! git -C "$DOTDIR" symbolic-ref -q HEAD >/dev/null 2>&1; then
        echo "Detached HEAD detected in $DOTDIR." >&2
        echo "Check out a branch before syncing (e.g., git checkout master)." >&2
        return 1
    fi

    local current_branch
    current_branch=$(git -C "$DOTDIR" symbolic-ref --short HEAD 2>/dev/null)
    echo "Syncing $DOTDIR (branch: $current_branch)..."

    if ! git -C "$DOTDIR" pull --ff-only; then
        echo "Fast-forward only failed. The local branch has diverged from remote." >&2
        echo "Resolve the divergence manually: cd $DOTDIR && git status" >&2
        return 1
    fi

    echo "Sync complete."
}

process_sync() {
    if ! sync_repo; then
        die "Sync failed."
    fi
}

cmd_sync_help() {
    cat <<'EOF'
dotctl sync
  Pull the dotfiles repo safely (ff-only, clean state required).
EOF
}
