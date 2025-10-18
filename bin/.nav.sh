#!/usr/bin/env zsh
# Zsh-compatible navigation menu

# Load the reusable menu
. "$DOTFILES/.lib/.menu.sh"

# Ensure aliases for navigation exist
. "$DOTFILES/.aliases/.freelancing.sh"
. "$DOTFILES/.aliases/.navigation.sh"

# Handlers
go_tmp() { cd /tmp && echo "Now in $PWD"; }

# Define menu options
typeset -A nav_options
nav_options=(
  ["Learning"]="lrn"
  ["Freelance"]="tpp"
  ["Temp"]="go_tmp"
)

# Run the menu
menu nav_options
