#!/usr/bin/env bash
set -euo pipefail

: "${DOTDIR:="$HOME/.dots"}"
DATADIR="$HOME/.local/share/dotctl"
mkdir -p "$DATADIR"

declare -a INSTALL_PLAN=()
declare -A RESOLVED_PACKAGES=()
declare -A VISITING_PACKAGES=()

die() {
    echo "$*" >&2
    exit 1
}

contains() {
    local needle="$1"
    shift

    local value
    for value in "$@"; do
        [[ "$value" == "$needle" ]] && return 0
    done
    return 1
}

confirm() {
    if [[ "$YES" == "true" ]]; then
        return 0
    fi

    local prompt="$1"
    local answer
    read -r -p "$prompt [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

pick_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        echo "paru"
        return
    fi

    if command -v yay >/dev/null 2>&1; then
        echo "yay"
        return
    fi

    echo "No AUR helper found."
    if confirm "Install paru?"; then
        sudo pacman -S --needed --noconfirm base-devel
        mkdir -p "$HOME/tmp"
        pushd "$HOME/tmp" >/dev/null
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si
        popd >/dev/null
        echo "paru"
    else
        echo ""
    fi
}

path_is_within() {
    local path="$1"
    local parent="$2"

    [[ "$path" == "$parent" || "$path" == "$parent"/* ]]
}

normalize_path() {
    realpath -m -s "$1"
}

is_managed_symlink() {
    local path="$1"

    [[ -L "$path" ]] || return 1

    local real_dest
    real_dest=$(realpath "$path" 2>/dev/null) || return 1

    [[ -e "$real_dest" ]] || return 1

    path_is_within "$real_dest" "$DOTDIR"
}

pkg_commit() {
    git -C "$DOTDIR" log -1 --format=%H -- "$1"
}

installed_commit_file() {
    echo "$DATADIR/$1.commit"
}

get_installed_commit() {
    local file
    file=$(installed_commit_file "$1")
    [[ -f "$file" ]] && <"$file" tr -d '\n' || echo ""
}

set_installed_commit() {
    printf '%s\n' "$2" >"$(installed_commit_file "$1")"
}
