# Cargo
. "$HOME/.cargo/env"

# Homebrew if exists
if [[ -s "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Rye if exists
if [[ -s "$HOME/.rye/env" ]]; then
  . "$HOME/.rye/env"
fi

# Activate local binaries
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Activate psql
if [[ -d "/opt/homebrew/opt/libpq/bin" ]]; then
  export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
fi

# Activate mojo
if [[ -d "$HOME/.modular" ]]; then
  export MODULAR_HOME="$HOME/.modular"
  export PATH="$MODULAR_HOME/pkg/packages.modular.com_mojo/bin:$PATH"
fi

# Add Visual Studio Code (code) in MacOS
if [ $(uname -s) = "Darwin" ]; then
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

# if [[ -s "$HOME/.pyenv/" ]]; then
#   export PYENV_ROOT="$HOME/.pyenv"
#   export PATH="$PYENV_ROOT/bin:$PATH"
#   eval "$(pyenv init --path)"
#   eval "$(pyenv init -)"
# fi

# if [[ -s "$HOME/.nvm/" ]]; then
#   export NVM_DIR="$HOME/.nvm"
#   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#   [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# fi
