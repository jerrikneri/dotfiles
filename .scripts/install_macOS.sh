echo 'Starting MacOS install script...'

# Homebrew
if command -v brew &> /dev/null; then
  echo 'Homebrew detected. Skipping install.'
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew bundle --file=$DOTFILES/macOS/Brewfile
fi

ln -sf $DOTFILES_CONFIG/zsh/.zshenv $HOME/.zshenv

echo "XDG_CONFIG_HOME is $XDG_CONFIG_HOME"
echo "DOTFILES_CONFIG is $DOTFILES_CONFIG"

ln -sf $DOTFILES_CONFIG/alacritty $XDG_CONFIG_HOME
ln -sf $DOTFILES_CONFIG/karabiner $XDG_CONFIG_HOME
ln -sf $DOTFILES_CONFIG/newsboat $XDG_CONFIG_HOME
ln -sf $DOTFILES_CONFIG/nvim $XDG_CONFIG_HOME
ln -sf $DOTFILES_CONFIG/tmuxinator $XDG_CONFIG_HOME

source $SCRIPTS/install_shared.sh

echo 'MacOS set up complete!'
