#!/usr/bin/env bash

echo 'Starting NixOS install script...'

# Clean up existing config
rm -f $HOME/.zshenv
rm -f $ZDOTDIR/.zshrc

ln -s "$DOTFILES_CONFIG/zsh/.zshenv" "$HOME/.zshenv"

mkdir -p $XDG_CONFIG_HOME

########
# nvim #
########

# Vanill nvim
#mkdir -p "$XDG_CONFIG_HOME/nvim"
#mkdir -p "$XDG_CONFIG_HOME/nvim/undo"

#ln -sf "$DOTFILES_CONFIG/nvim/init.nvim" "$XDG_CONFIG_HOME/nvim"
# -s symbolic otherwise it will create a hard link
# -f force creation of link, remove existing if any

# Entire directory for LazyVim
ln -sf $DOTFILES_CONFIG/nvim $XDG_CONFIG_HOME
# ln -sf $DOTFILES_CONFIG/kdedefaults $XDG_CONFIG_HOME

# Link entire directory -f not needed as we wipe existing, and can't be used on directories

#########
# fonts #
#########

mkdir -p "$XDG_DATA_HOME"
cp -rf "$DOTFILES/fonts" "$XDG_DATA_HOME"

source $SCRIPTS/install_shared.sh

echo 'NixOS set up complete!'
