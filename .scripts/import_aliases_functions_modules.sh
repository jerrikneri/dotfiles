#!/usr/bin/env bash

source $DOTFILES/.env

echo 'Sourcing aliases, functions, and modules...'

echo "Environment Setup Level is $SETUP_ENVIRONMENT_LEVEL"

if [ $SETUP_ENVIRONMENT_LEVEL = "full" ]; then
  # defined in .config/zsh/.zshenv
  source $SCRIPTS/source_all.sh
  source-all
else
  source $ALIASES/.essential.sh
  source $FUNCTIONS/.essential.sh
fi

