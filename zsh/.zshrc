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
setopt EXTENDED_GLOB
setopt REMATCH_PCRE

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
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
}

GIT_AUTO_FETCH_INTERVAL=300 # 5 minutes

# Plugins that need immediate loading
zi light-mode depth"1" for \
    romkatv/powerlevel10k \
    jeffreytse/zsh-vi-mode \

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
if command -v "eza" &>/dev/null; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'  # preview directory's content with eza when completing cd
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

# Useful aliases
alias '..'='cd ..'
alias less='less -R'

if command -v eza &>/dev/null; then
    alias ls='eza --icons=auto --color=auto --group-directories-first'
    alias la='ls -a'
    alias ll='ls -lh --git --git-repos'
else
    alias ls='ls --color=auto'
    alias la='ls -a'
    alias ll='ls -lh'
fi

if command -v bat &>/dev/null; then
    alias cat='bat --style=plain'
fi

if command -v trash &>/dev/null; then
    alias rm='trash'
fi

if command -v nvim &>/dev/null; then
    alias v='nvim'
fi

if command -v lazygit &>/dev/null; then
    alias lg='lazygit'
fi

if command -v thefuck &>/dev/null; then
    eval "$(thefuck -a fuck)"
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init --cmd cd zsh)"
fi

if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

# If lf exists
if command -v lf &>/dev/null; then
    function l() {
        emulate -L zsh
        local dir
        dir="$(lf -print-last-dir "$@")" || return
        [[ -n "$dir" && "$dir" != "$PWD" && -d "$dir" ]] && builtin cd -- "$dir"
    }
fi

# Android dev environment
export ANDROID_HOME="${HOME}/Android/Sdk"
# export ANDROID_SDK_ROOT="${ANDROID_HOME}"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"
# Flutter
export PATH="$HOME/.flutter/flutter/bin:$PATH"

# Dart completions
[[ -f ~/.dart-cli-completion/zsh-config.zsh ]] && . ~/.dart-cli-completion/zsh-config.zsh || true

# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    nvm() {
        unset -f nvm
        . "$NVM_DIR/nvm.sh" --no-use
        nvm "$@"
    }
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
