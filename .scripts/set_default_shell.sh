#!/usr/bin/env bash

# Get the current default shell for the user
current_shell=$(echo "$SHELL")

# Path to zsh
zsh_path="/bin/zsh"

# Check if the current shell is not zsh
if [ "$current_shell" != "$zsh_path" ]; then
  echo "Current shell is not zsh, changing to zsh..."
  
  # Check if zsh is installed
  if ! command -v zsh >/dev/null 2>&1; then
    echo "zsh is not installed. Please install zsh first."
    exit 1
  fi

  # Change default shell to zsh
  chsh -s "$zsh_path"

  if [ $? -eq 0 ]; then
    echo "Default shell successfully changed to zsh."
  else
    echo "Failed to change default shell."
    exit 1
  fi
else
  echo "Default shell is already zsh."
fi

