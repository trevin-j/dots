# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$PATH:$HOME/.local/bin"

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

apply_shell_keybinds() {
    bindkey -v
    bindkey -r '^h'
    bindkey '^h' backward-kill-word
}

typeset -ga zvm_after_init_commands
zvm_after_init_commands+=(apply_shell_keybinds)

GIT_AUTO_FETCH_INTERVAL=300 # 5 minutes

# Plugins that need immediate loading
zi light-mode depth"1" for \
    romkatv/powerlevel10k \
    jeffreytse/zsh-vi-mode \

# Asynchronous plugin loading
zi wait lucid light-mode for \
    Aloxaf/fzf-tab \
    hlissner/zsh-autopair \
    has"eza" as"completion" https://github.com/eza-community/eza/blob/main/completions/zsh/_eza \
    blockf \
        zsh-users/zsh-completions \
    atload"zicompinit; zicdreplay" \
        zsh-users/zsh-syntax-highlighting \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \

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

# Lower esc key delay for vi mode to 0.05s
export KEYTIMEOUT=5

# Useful aliases
alias '..'='cd ..'
alias less='less -R'

alias ls='ls --color=auto -l'
if command -v eza &>/dev/null; then
    alias ls='eza -l --color=auto --icons=auto --group-directories-first'
fi
alias la='ls -alh'

if command -v bat &>/dev/null; then
    alias cat='bat --style=plain'
fi

if command -v trash &>/dev/null; then
    alias rm='trash'
fi

alias lg='lazygit'

if command -v thefuck &>/dev/null; then
    eval "$(thefuck -a fuck)"
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init --cmd cd zsh)"
fi

if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
    apply_shell_keybinds
fi

# If lf exists
if command -v lf &>/dev/null; then
    lfpath="$(which lf)"
    function lf() {
        emulate -L zsh
        local dir
        dir="$($lfpath -print-last-dir "$@")" || return
        [[ -n "$dir" && "$dir" != "$PWD" && -d "$dir" ]] && builtin cd -- "$dir"
    }
fi

dev_tools_zsh="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/dev-tools.zsh"
[[ -r "$dev_tools_zsh" ]] && source "$dev_tools_zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
