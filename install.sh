#!/usr/bin/env bash


# Source base environment variables for establishing directories
source .config/zsh/.zshenv

if [ -f "$HOME/.zshenv" ]; then
  cp "$HOME/.zshenv" "$HOME/.zshenv.old"
else
  echo "File $HOME/.zshenv does not exist."
fi
if [ -f "$HOME/.zshrc" ]; then
  cp $ZDOTDIR/.zshrc $ZDOTDIR/.zshrc.old
else
  echo "File $HOME/.zshrc does not exist."
fi

rm -f $HOME/.zshenv
rm -f $ZDOTDIR/.zshrc

if [ ! -f .env ]; then
  cp .env.example .env
  echo ".env file created from .env.example"
else
  echo ".env file already exists"
fi

# Private Environment Variables
source $DOTFILES/.env

source $SCRIPTS/set_os.sh
# run install_arch.sh | install_macOS.sh | install_ubuntu.sh
$SCRIPTS/detect_os.sh

echo 'Install complete! Sourcing .zshrc'
