# Dotfiles

## Setup

1. Clone repo to directory of your choice.
2. Modify export REPOS="$HOME/code"
    export DOTFILES="$REPOS/dotfiles"
    based on where you've cloned this repo.
3. `./install.sh`
4. Source your original profile.

## Testing

- Run all bash tests: `bats tests/bash`
- Run a single suite: `bats tests/bash/worktree.bats`
- Lint shell scripts: `shellcheck install.sh .scripts/*.sh .functions/*.sh bin/*.sh`
