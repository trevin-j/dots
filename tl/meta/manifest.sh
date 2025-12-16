export requires=()
export require_aur="false"
export deps=(fzf kitty cliphist wl-clipboard wtype rbw)
post_stow() {
    data_dir="$HOME/.local/share/tl"
    curl -sL "https://github.com/milesj/emojibase/raw/refs/heads/master/packages/data/en/compact.raw.json" -o "$data_dir/emoji.json" || return 1
    curl -sL "https://github.com/ryanoasis/nerd-fonts/raw/refs/heads/master/glyphnames.json" -o "$data_dir/nerd-font-icons.json" || return 1
}
