export requires=()
export require_aur="false"
export deps=(fzf kitty cliphist wl-clipboard wtype rbw)
post_stow() {
    data_file="$HOME/.local/share/tl/emoji.json"
    curl -sL "https://github.com/milesj/emojibase/raw/refs/heads/master/packages/data/en/compact.raw.json" -o "$data_file" || return 1
}
