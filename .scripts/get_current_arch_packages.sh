#!/usr/bin/env bash

# List user-installed packages from pacman
pacman -Qq > $DOTFILES/arch/pacmans

# List AUR packages
yay -Qm | awk '{print $1}' > $DOTFILES/arch/yays

# Combine the lists and remove duplicates
cat $DOTFILES/arch/pacmans $DOTFILES/arch/yays | sort | uniq > $DOTFILES/arch/packages

