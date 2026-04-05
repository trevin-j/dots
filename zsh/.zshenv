# Ensure unique entries in PATH
typeset -U path PATH

# Set PATH directories
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  $path
)

# Add .dotnet/tools only if it exists
[[ -d "$HOME/.dotnet/tools" ]] && path+=("$HOME/.dotnet/tools")

# Export necessary environment variables
export EDITOR="nvim"
export VISUAL="nvim"
export LANG="en_US.UTF-8"

# Source Cargo if available
[[ -f ~/.cargo/env ]] && source ~/.cargo/env
