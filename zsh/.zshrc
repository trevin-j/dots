# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
# setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt append_history

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export OPENER=mimeopen

# If git is not installed, tell the user it is needed for full functionality then exit.
if ! command -v git &>/dev/null; then
  echo "Git is required for full functionality for this zsh config! Please install it."
  exit 1
fi

# zinit setup
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Better vim mode config
ZVM_INIT_MODE=sourcing # Fix overriding binds that are specified later
zvm_config() {
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
}

GIT_AUTO_FETCH_INTERVAL=300 # 5 minutes

# Plugins that need immediate loading
zi light-mode depth"1" for \
    jeffreytse/zsh-vi-mode \
    romkatv/powerlevel10k \
    trevin-j/azaleas \

# Any commands or binds that should override any plugin options
# These are technically run after every individual plugin is loaded, which isn't great
# but so far it is the only way to reliably override binds, etc after loading without relying on timing
override_cmds()
{
    bindkey -r "^h"
    bindkey "^h" backward-kill-word
}

# Asynchronous plugin loading
zi wait lucid light-mode atload"override_cmds" for \
    OMZP::colored-man-pages/colored-man-pages.plugin.zsh \
    OMZP::command-not-found/command-not-found.plugin.zsh \
    OMZP::copybuffer/copybuffer.plugin.zsh \
    Aloxaf/fzf-tab \
    hlissner/zsh-autopair \
    has"eza" as"completion" https://github.com/eza-community/eza/blob/main/completions/zsh/_eza \
    as"program" pick"$ZPFX/bin/git-*" src"etc/git-extras-completion.zsh" make"PREFIX=$ZPFX" \
        tj/git-extras \
    blockf \
        zsh-users/zsh-completions \
    atload"zicompinit; zicdreplay" \
        zsh-users/zsh-syntax-highlighting \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \

# commant-not-found
# -------------------------------------------------------
# Suggest how to install missing commands. Requires a command-not-found package for your distro.
# For Arch, this is pkgfile. Install it and run `sudo pkgfile -u` to update the database.
# Add pkgfile updates to systemd by `sudo systemctl enable pkgfile-update.timer`

# copy plugins
# -------------------------------------------------------
# Quickly copy stuff. Use ctrl+o to copy current buffer to clipboard.

# Fzf for tab completion!

# Autopair characters like parentheses or brackets

# Completion style settings (for use with fzf-tab plugin)
zstyle ':completion:*:git-checkout:*' sort false        # disable sort when completing `git checkout`
zstyle ':completion:*:descriptions' format '[%d]'       # set descriptions format to enable group support
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}   # set list-colors to enable filename colorizing
zstyle ':completion:*' menu no                          # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
if command -v "exa" &>/dev/null; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'  # preview directory's content with eza when completing cd
fi
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept   # custom fzf flags
zstyle ':fzf-tab:*' use-fzf-default-opts yes            # To make fzf-tab follow FZF_DEFAULT_OPTS.
zstyle ':fzf-tab:*' switch-group '<' '>'                # switch group using `<` and `>`

# Use vim bindings
bindkey -v

# Lower esc key delay for vi mode to 0.05s
export KEYTIMEOUT=5

# Bind reverse search (obsolete if fzf is installed)
bindkey "^R" history-incremental-search-backward

# General aliases - don't have any dependencies
typeset -A ALIAS_REGISTRY=(
    ls "ls --color=auto"
    grep "grep --color=auto"
    less "less -R"
    .. "cd .."
)

azaleas_register

# Misc aliases with dependencies
typeset -a SINGLES_ALIASES=(
    "nvim:v:nvim"
    "lazygit:lg:lazygit"
    "bat:cat:bat --style=plain"
    "rg:grep:rg"
)

# Misc commands that must run on startup with dependencies
typeset -a SINGLES_COMMANDS=(
    "thefuck:eval \"\$(thefuck -a crap)\"" # Type `crap` and it will suggest a fix
    "zoxide:eval \"\$(zoxide init --cmd cd zsh)\""
    "fzf:source <(fzf --zsh)"
)

azaleas_register_singles

typeset -A ALIAS_REGISTRY=(
    ls 'eza --icons=auto --color=auto --group-directories-first'
    lsf "ls -f"
    lsd "ls -D"
    lsa "ls -a"
    lsaf "lsa -f"
    lsad "lsa -D"
    lsl "ls -lh --git --git-repos"
    lslf "lsl -f"
    lsld "lsl -D"
    lsla "lsl -a"
    lsal "lsl -a"
    lslaf "lsla -f"
    lslad "lsla -D"
    lsls "lsl --total-size"
    lslas "lsls -a"
    lst "ls -T --level=2"
    lstf "lst -f"
    lstd "lst -D"
    lsta "lst -a"
    lstaf "lsta -f"
    lstad "lsta -D"
)

azaleas_register eza

# pnpm aliases
typeset -A ALIAS_REGISTRY=(
    # local
    pn "pnpm"
    pnx "pnpm dlx"
    pna "pnpm add"
    pnad "pnpm add --save-dev"
    pnap "pnpm add --save-peer"
    pnrm "pnpm remove"
    pni "pnpm install"
    pnu "pnpm uninstall"
    pnl "pnpm list"
    pnup "pnpm update --interactive --latest"
    pno "pnpm outdated"
    pnc "pnpm create"
    pnau "pnpm audit"
    pnw "pnpm why"

    # global
    pnga "pnpm add --global"
    pngl "pnpm list --global"
    pngr "pnpm remove --global"
    pngu "pnpm update --global"

    # scripts
    pnr "pnpm run"
    pnrd "pnpm run dev"
    pnrb "pnpm run build"
    pnrl "pnpm run lint"
    pnrlf "pnpm run lint --fix"
    pnrs "pnpm run serve"
    pndoc "pnpm run doc"
    pnt "pnpm test"
    pntc "pnpm test --coverage"
)

azaleas_register pnpm

# If yazi exists
if command -v yazi &>/dev/null; then
    function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    }
fi

# If lf exists
if command -v lf &>/dev/null; then
    function l() {
        cd "$(lf -print-last-dir)"
    }
fi

# Android dev environment
export ANDROID_HOME="${HOME}/Android/Sdk"
# export ANDROID_SDK_ROOT="${ANDROID_HOME}"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"
# Flutter
export PATH="$HOME/.flutter/flutter/bin:$PATH"

# Local env settings! Add your local settings to ~/.localrc.
if [[ -f ~/.localrc ]]; then
    source ~/.localrc
fi

# Dart completions
[[ -f ~/.dart-cli-completion/zsh-config.zsh ]] && . ~/.dart-cli-completion/zsh-config.zsh || true

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
