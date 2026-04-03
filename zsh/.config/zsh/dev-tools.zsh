export ANDROID_HOME="${HOME}/Android/Sdk"

if [[ -d "$ANDROID_HOME/emulator" ]]; then
    path+=("$ANDROID_HOME/emulator")
fi

if [[ -d "$ANDROID_HOME/platform-tools" ]]; then
    path+=("$ANDROID_HOME/platform-tools")
fi

if [[ -d "$HOME/.flutter/flutter/bin" ]]; then
    path=("$HOME/.flutter/flutter/bin" $path)
fi

[[ -f ~/.dart-cli-completion/zsh-config.zsh ]] && source ~/.dart-cli-completion/zsh-config.zsh

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _lazy_load_nvm() {
        unset -f nvm _lazy_load_nvm
        source "$NVM_DIR/nvm.sh" --no-use
    }

    nvm() {
        _lazy_load_nvm
        nvm "$@"
    }
fi
