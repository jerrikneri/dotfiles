# Bash
alias la="ls -al"

# CLI Tools
alias k="kubectl"
alias nv="nvim"
alias t="tmux"
alias txt="tmuxinator"

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
alias gclb="git fetch -p && for branch in `git branch -vv | grep ': gone]' | awk '{print $1}'`; do git branch -D $branch; done"

# Navigation
alias c="cd $HOME/code"
alias cfg="cd $DOTFILES"
alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index