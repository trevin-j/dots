export requires=(foot theming zellij)
export pacman_deps=(
    dolphin ark audiocd-kio baloo dolphin-plugins kio-admin kompare konsole ffmpegthumbs icoutils kdegraphics-thumbnailers kdesdk-thumbnailers kimageformats libappimage qt6-imageformats resvg taglib
    firefox
    brightnessctl
    cliphist
    curl
    jq
    pinentry
    rbw
    wl-clipboard
    wtype
    hyprpolkitagent
    hyprland
    kdeconnect
    hyprsunset
    grim slurp
    quickshell
    ttf-material-symbols-variable
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-kde
    pipewire wireplumber pipewire-pulse
)
export aur_deps=(
    bibata-cursor-theme-bin
    wvkbd-git
)

post_stow() {
    if command -v configure-rbw-pinentry >/dev/null 2>&1; then
        configure-rbw-pinentry --quiet || true
    fi
    if command -v update-quickshell-symbol-data >/dev/null 2>&1; then
        update-quickshell-symbol-data --force --quiet || true
    fi
    if command -v build-quickshell-symbol-cache >/dev/null 2>&1; then
        build-quickshell-symbol-cache --kind emoji --data-file "${XDG_DATA_HOME:-$HOME/.local/share}/quickshell/symbol-picker/emoji.json" --mru-file "${XDG_DATA_HOME:-$HOME/.local/share}/quickshell/symbol-picker/emoji-mru" --cache-file "${XDG_DATA_HOME:-$HOME/.local/share}/quickshell/symbol-picker/emoji-cache.json" || true
        build-quickshell-symbol-cache --kind nerdfont --data-file "${XDG_DATA_HOME:-$HOME/.local/share}/quickshell/symbol-picker/nerd-font-icons.json" --mru-file "${XDG_DATA_HOME:-$HOME/.local/share}/quickshell/symbol-picker/nerdfont-mru" --cache-file "${XDG_DATA_HOME:-$HOME/.local/share}/quickshell/symbol-picker/nerdfont-cache.json" || true
    fi
}
