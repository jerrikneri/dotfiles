#!/usr/bin/env bash

# Define an array of programs you want to keep
keep_programs=("koekeishiya/formulae/skhd" "bitwarden-cli" "helm" "k9s" "mycli" "neovim" "newsboat" "pgcli" "ripgrep" "tailscale" "tmux" "wakeonlan")

# Function to check if a program is in the keep list
should_keep() {
  local program=$1
  for keep in "${keep_programs[@]}"; do
    if [[ $keep == $program ]]; then
      return 0 # Return 0 if the program is in the keep list
    fi
  done
  return 1 # Return 1 if the program is not in the keep list
}

# Fetch the list of leaves (packages that are not dependencies of other packages)
leaves=$(brew leaves)

# Iterate over each leaf package
for leaf in $leaves; do
  if should_keep "$leaf"; then
    echo "Keeping $leaf..."
  else
    echo "Uninstalling $leaf..."
    brew uninstall $leaf
  fi
done

echo "Process complete."
