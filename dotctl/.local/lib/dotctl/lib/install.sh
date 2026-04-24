#!/usr/bin/env bash

load_manifest() {
    local manifest="$1"
    local line key value in_array

    requires=()
    pacman_deps=()
    aur_deps=()
    in_array=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line#"${line%%[![:space:]]*}"}
        [[ -z "$line" || "$line" == \#* ]] && continue

        if [[ "$line" =~ ^export\ (requires|pacman_deps|aur_deps|deps)=\( ]]; then
            key="${line#export }"
            key="${key%%=*}"
            in_array="$key"
            # If same-line format like "export requires=(foo bar)", process now
            if [[ "$line" == *")"* ]]; then
                value="${line#*(}"
                value="${value%)}"
                value="${value//[\'\"]/}"
                read -ra parts <<< "$value"
                for part in "${parts[@]}"; do
                    [[ -z "$part" ]] && continue
                    case "$in_array" in
                        requires)   requires+=("$part") ;;
                        pacman_deps) pacman_deps+=("$part") ;;
                        aur_deps)    aur_deps+=("$part") ;;
                    esac
                done
                in_array=""
            fi
            continue
        fi

        if [[ -n "$in_array" ]]; then
            if [[ "$line" == ")" ]]; then
                in_array=""
                continue
            fi
            # Handle same-line closing paren: "foo bar)" or "(foo bar)"
            if [[ "$line" == *")"* ]]; then
                value="${line%)*}"
            else
                value="$line"
            fi
            value="${value//[\'\"]/}"
            read -ra parts <<< "$value"
            for part in "${parts[@]}"; do
                [[ -z "$part" ]] && continue
                case "$in_array" in
                    requires)   requires+=("$part") ;;
                    pacman_deps) pacman_deps+=("$part") ;;
                    aur_deps)    aur_deps+=("$part") ;;
                esac
            done
            # If same-line closing paren, done with this array
            if [[ "$line" == *")"* ]]; then
                in_array=""
            fi
        fi
    done < "$manifest"
}

run_pkg_hook() {
    local pkg="$1"
    local pkgdir="$2"
    local hook_name="$3"
    local hook_file="$pkgdir/meta/$hook_name"

    [[ -x "$hook_file" ]] || return 0

    DOTDIR="$DOTDIR" \
    DATADIR="$DATADIR" \
    PACKAGE="$pkg" \
    PACKAGE_DIR="$pkgdir" \
    HOME="$HOME" \
    "$hook_file"
}

pkg_is_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}

handle_deps() {
    local manager="$1"
    shift
    local deps=("$@")

    [[ ${#deps[@]} -eq 0 ]] && return

    local missing=()
    local dep
    for dep in "${deps[@]}"; do
        if ! pkg_is_installed "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        echo "All ${manager} deps already installed: ${deps[*]}"
        return
    fi

    echo "Installing missing ${manager} deps: ${missing[*]}"

    local installer=(sudo pacman -S --needed --noconfirm)
    if [[ "$manager" == "aur" ]]; then
        local helper
        helper=$(pick_aur_helper)
        if [[ -z "$helper" ]]; then
            echo "Cannot install AUR deps without helper. Skipping deps."
            return
        fi
        installer=("$helper" -S --needed --noconfirm)
    fi

    "${installer[@]}" "${missing[@]}"
}

detect_package_conflicts() {
    local pkg="$1"
    local pkgdir="$DOTDIR/$pkg"

    mapfile -t conflicts < <(
        while IFS= read -r item; do
            [[ -f "$item" ]] || continue

            local rel_path="${item#$pkgdir/}"
            local target="$HOME/$rel_path"

            if [[ -d "$target" ]]; then
                continue
            fi

            if [[ -e "$target" || -L "$target" ]]; then
                if ! is_managed_symlink "$target"; then
                    printf '%s\n' "$rel_path"
                fi
            fi
        done < <(find "$pkgdir" -type f 2>/dev/null)
    )

    if ((${#conflicts[@]} == 0)); then
        return
    fi

    echo "Conflicts detected in package '$pkg':"
    local conflict
    for conflict in "${conflicts[@]}"; do
        echo "  ~/$conflict"
    done

    local should_proceed="false"
    if [[ "$YES" == "true" ]]; then
        should_proceed="true"
    elif confirm "Back up conflicting files and replace?"; then
        should_proceed="true"
    fi

    if [[ "$should_proceed" != "true" ]]; then
        die "Aborting."
    fi

    for conflict in "${conflicts[@]}"; do
        local backup="$HOME/$conflict.backup.$(date +%s)"
        echo "Backing up ~/$conflict -> $backup"
        mv "$HOME/$conflict" "$backup"
    done
}

check_stow_sanity() {
    local pkg="$1"

    local unexpected
    mapfile -t unexpected < <(
        stow --dir="$DOTDIR" --target="$HOME" --no-folding -nv "$pkg" 2>&1 \
            | sed -n 's/.*existing target \(.*\) since.*/\1/p'
    )

    if ((${#unexpected[@]} != 0)); then
        echo "Unexpected conflicts remain after backup:" >&2
        printf '  %s\n' "${unexpected[@]}" >&2
        die "Sanity check failed. Aborting to avoid data loss."
    fi
}

backup_conflicts() {
    local pkg="$1"

    echo "Checking for conflicts..."
    detect_package_conflicts "$pkg"
    check_stow_sanity "$pkg"
}

resolve_pkg_plan() {
    local pkg="$1"
    local pkgdir="$DOTDIR/$pkg"
    local manifest="$pkgdir/meta/manifest.sh"

    if [[ -n "${RESOLVED_PACKAGES[$pkg]:-}" ]]; then
        return
    fi

    if [[ -n "${VISITING_PACKAGES[$pkg]:-}" ]]; then
        die "Dependency cycle detected while resolving '$pkg'."
    fi

    [[ -d "$pkgdir" ]] || die "Package $pkg not found."
    [[ -f "$manifest" ]] || die "No manifest for $pkg. Aborting."

    VISITING_PACKAGES[$pkg]=1
    load_manifest "$manifest"

    local req
    for req in "${requires[@]}"; do
        resolve_pkg_plan "$req"
    done

    unset 'VISITING_PACKAGES[$pkg]'
    RESOLVED_PACKAGES[$pkg]=1
    INSTALL_PLAN+=("$pkg")
}

perform_install_pkg() {
    local pkg="$1"
    local pkgdir="$DOTDIR/$pkg"
    local manifest="$pkgdir/meta/manifest.sh"
    local force="${DOTCTL_FORCE:-false}"
    local current_commit installed_commit

    current_commit=$(pkg_commit "$pkg")
    installed_commit=$(get_installed_commit "$pkg")

    echo "Current commit: $current_commit"
    echo "Installed commit: $installed_commit"

    if [[ "$force" != "true" ]] \
        && [[ -n "$current_commit" ]] \
        && [[ "$current_commit" == "$installed_commit" ]]; then
        echo "Skipping $pkg (no changes)"
        return 0
    fi

    if [[ ! -f "$manifest" ]]; then
        echo "warning: package '$pkg' has no manifest (may have been removed from repo). Skipping."
        return 0
    fi

    load_manifest "$manifest"

    echo
    echo "=== Installing $pkg ==="
    run_pkg_hook "$pkg" "$pkgdir" pre_dl
    handle_deps pacman "${pacman_deps[@]}"
    handle_deps aur "${aur_deps[@]}"
    run_pkg_hook "$pkg" "$pkgdir" pre_stow
    backup_conflicts "$pkg"
    echo "Stowing $pkg..."
    stow --dir="$DOTDIR" --target="$HOME" --no-folding "$pkg"
    run_pkg_hook "$pkg" "$pkgdir" post_stow
    echo "Finished installing $pkg."

    if [[ -n "$current_commit" ]]; then
        set_installed_commit "$pkg" "$current_commit"
    fi
}

prune_stale_commits() {
    local stale=()
    while read -r pkg_file; do
        local pkg="${pkg_file%.commit}"
        pkg="${pkg##*/}"
        if [[ ! -f "$DOTDIR/$pkg/meta/manifest.sh" ]]; then
            stale+=("$pkg")
        fi
    done < <(find "$DATADIR" -type f -name '*.commit')

    if ((${#stale[@]} == 0)); then
        return
    fi

    echo "Removing stale commit records for packages no longer in repo:"
    local pkg
    for pkg in "${stale[@]}"; do
        echo "  ~/$pkg (will not be upgraded)"
        rm -f "$DATADIR/$pkg.commit"
    done
}

cmd_install_help() {
    cat <<'EOF'
dotctl [--force] [--local] [-y] install [PKG|PKG PKG|all]
  Install one or more packages.
EOF
}
