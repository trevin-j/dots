export requires=(foot theming waybar)
export require_aur="true"
export deps=(
    sudo bash coreutils
    archlinux-xdg-menu
    dolphin kservice ark audiocd-kio baloo dolphin-plugins kio-admin kompare konsole ffmpegthumbs icoutils kdegraphics-thumbnailers kdesdk-thumbnailers kimageformats libappimage qt6-imageformats resvg taglib
    firefox
    brightnessctl
    wl-clipboard
    swaync
    hyprpolkitagent
    hyprland
    kdeconnect
    hyprsunset
    bibata-cursor-theme-bin
    grim slurp
    quickshell
)

pre_dl() {
    # Here we want to automatically update dolphin's available programs on every system upgrade/install/removal.
    sudo pacman -S --needed archlinux-xdg-menu sudo bash coreutils kservice
    # The above are required deps in order to process apps.
    # Copy the hook to where it should go
    sudo mkdir -p /etc/pacman.d/hooks/
    sudo cp "$DOTDIR/hyprland/meta/updateKDEcache.hook" /etc/pacman.d/hooks/updateKDEcache.hook
}
