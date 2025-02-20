#!/bin/bash

source $DOTFILES/.env

echo 'Sourcing aliases, functions, and modules...'

echo "Environment Setup Level is $SETUP_ENVIRONMENT_LEVEL"

if [ $SETUP_ENVIRONMENT_LEVEL = "full" ]; then
  # defined in .config/zsh/.zshenv
  for dir in $ALIASES $FUNCTIONS $MODULES; do
    for file in "$dir"/.*.sh; do
      [ -f "$file" ] && source $file
    done
  done
else
  source $ALIASES/.essential.sh
  source $FUNCTIONS/.essential.sh
fi

