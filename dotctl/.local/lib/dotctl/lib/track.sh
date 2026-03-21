#!/usr/bin/env bash

ensure_package_exists() {
    local package="$1"
    local pkgdir="$DOTDIR/$package"
    local template_dir="$DOTDIR/_package_template"

    if [[ -d "$pkgdir" ]]; then
        return
    fi

    [[ -d "$template_dir" ]] || die "Template package not found: $template_dir"

    echo "Creating new package '$package' from template..."
    cp -r "$template_dir" "$pkgdir"
}

path_home_relative() {
    local absolute_path="$1"

    path_is_within "$absolute_path" "$HOME" || die "Path must live inside $HOME: $absolute_path"
    [[ "$absolute_path" != "$HOME" ]] || die "Refusing to track your home directory root."

    echo "${absolute_path#"$HOME"/}"
}

path_is_already_tracked() {
    local absolute_path="$1"

    if [[ ! -e "$absolute_path" && ! -L "$absolute_path" ]]; then
        return 1
    fi

    local resolved_path
    resolved_path=$(realpath "$absolute_path")
    path_is_within "$resolved_path" "$DOTDIR"
}

same_realpath() {
    local left="$1"
    local right="$2"

    [[ -e "$left" || -L "$left" ]] || return 1
    [[ -e "$right" || -L "$right" ]] || return 1
    [[ "$(realpath "$left")" == "$(realpath "$right")" ]]
}

merge_directory_into_destination() {
    local source_dir="$1"
    local destination_dir="$2"
    local source_entry destination_entry

    mkdir -p "$destination_dir"

    shopt -s dotglob nullglob
    for source_entry in "$source_dir"/*; do
        [[ -e "$source_entry" || -L "$source_entry" ]] || continue
        destination_entry="$destination_dir/$(basename "$source_entry")"

        if [[ -L "$source_entry" ]] && same_realpath "$source_entry" "$destination_entry"; then
            continue
        fi

        if [[ -d "$source_entry" && ! -L "$source_entry" ]]; then
            if [[ -e "$destination_entry" || -L "$destination_entry" ]]; then
                if [[ -d "$destination_entry" && ! -L "$destination_entry" ]]; then
                    merge_directory_into_destination "$source_entry" "$destination_entry"
                    rmdir "$source_entry" 2>/dev/null || true
                    continue
                fi

                die "Destination already exists in package '$package': $destination_entry"
            fi

            mv "$source_entry" "$destination_entry"
            continue
        fi

        if [[ -e "$destination_entry" || -L "$destination_entry" ]]; then
            if same_realpath "$source_entry" "$destination_entry"; then
                continue
            fi

            die "Destination already exists in package '$package': $destination_entry"
        fi

        mv "$source_entry" "$destination_entry"
    done
    shopt -u dotglob nullglob
}

track_one_path() {
    local package="$1"
    local raw_path="$2"
    local pkgdir="$DOTDIR/$package"
    local absolute_path relative_path destination

    absolute_path=$(normalize_path "$raw_path")
    path_is_within "$absolute_path" "$DOTDIR" && die "Refusing to track a path inside DOTDIR: $absolute_path"
    relative_path=$(path_home_relative "$absolute_path")

    if path_is_already_tracked "$absolute_path"; then
        echo "Skipping already tracked path: ~/$relative_path"
        return
    fi

    if [[ ! -e "$absolute_path" && ! -L "$absolute_path" ]]; then
        die "Path does not exist: $absolute_path"
    fi

    destination="$pkgdir/$relative_path"
    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ -d "$absolute_path" && ! -L "$absolute_path" && -d "$destination" && ! -L "$destination" ]]; then
            merge_directory_into_destination "$absolute_path" "$destination"
            return
        fi

        if same_realpath "$absolute_path" "$destination"; then
            echo "Skipping already tracked path: ~/$relative_path"
            return
        fi

        die "Destination already exists in package '$package': $destination"
    fi

    mkdir -p "$(dirname "$destination")"
    mv "$absolute_path" "$destination"
}

process_track_pkg() {
    local package="$1"
    shift

    [[ $# -gt 0 ]] || die "Usage: dotctl track [package] [...paths]"

    ensure_package_exists "$package"

    local path
    for path in "$@"; do
        track_one_path "$package" "$path"
    done

    echo "Stowing $package..."
    stow --dir="$DOTDIR" --target="$HOME" --no-folding "$package"
}

cmd_track_help() {
    cat <<'EOF'
dotctl [--force] [-y] track [PACKAGE] [...PATH]
  Track an existing config into a package.
EOF
}

cmd_add_help() {
    cat <<'EOF'
dotctl [--force] [-y] add [PACKAGE] [...PATH]
  Alias for track.
EOF
}
