# Bash
alias la="ls -alG"
alias ls="ls -G"

# CLI Tools
alias b="brew"
alias cat="bat $1"
alias csv="column -t -s, $1"
alias d="docker"
alias k="kubectl"
#alias p="podman"
alias n="nvim"
alias t="tmux"
alias tnn="tmux new -s $1"
alias txt="tmuxinator"

# Docker -> Podman
# alias docker="podman"

# Git
alias gs="git status"
alias gl="git log"
alias gpom="git pull origin main"
alias gpoms="git pull origin master"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit -m"
alias gco="git checkout"
alias gps="git push"
alias gpl="git pull"
alias gd="git diff"
alias gf="git fetch"

# Lazy Tools
alias lad="lazydocker"
alias lag="lazygit"
alias las="lazysql"

# Navigation
alias c="cd $HOME/code"
alias cfg="cd $DOTFILES"
alias ncfg="cd $DOTFILES/nix"
alias nix-config="cd $DOTFILES/nix"
alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index

# Utility
alias weather="curl wttr.in"

# Sourcing
alias zsrc="source $ZDOTDIR/.zshrc"
