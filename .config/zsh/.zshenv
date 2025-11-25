# For dotfiles
export XDG_CONFIG_HOME="$HOME/.config"

# For specific data
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"

# For cached files
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

export EDITOR="nvim"
export VISUAL="nvim"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# History filepath
export HISTFILE="$ZDOTDIR/.zhistory"
# Maximum events for internal history
export HISTSIZE=50000
# Maximum events in history file
export SAVEHIST=50000

# fzf and ripgrep
export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# DO NOT ADD .zhistory to Git

############
# Personal #
############

# Directories
export REPOS="$HOME/code"
export DOTFILES="$REPOS/dotfiles"
export LAB="$REPOS/homelab"
export ALIASES="$DOTFILES/.aliases"
export DOTFILES_CONFIG="$DOTFILES/.config"
export FUNCTIONS="$DOTFILES/.functions"
export MODULES="$DOTFILES/.modules"
export SCRIPTS="$DOTFILES/.scripts"

# Docker
export FORMAT="\nID\t{{.ID}}\nIMAGE\t{{.Image}}\nCOMMAND\t{{.Command}}\nCREATED\t{{.RunningFor}}\nSTATUS\t{{.Status}}\nPORTS\t{{.Ports}}\nNames\t{{.Names}}\n"

# Kubernetes
export KUBECONFIG=~/.kube/config

# Nix
export NIX_SHARE_PATH="/run/current-system/sw/share"
