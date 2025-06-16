{ pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    alejandra # Uncompromising Nix Code Formatter
    bat # cat alternative
    diff-so-fancy
    fzf # Fuzzy Finder
    neovim
    gcc
    git
    nil # Nix Language Server
    ripgrep # Grep alternative
    tmux
    #vimPlugins.LazyVim
    wget
    zsh-syntax-highlighting
    zsh-vi-mode
    zsh # Shell
  ] ++ lib.optionals isLinux [
    distrobox
  ];
}

# Example for Darwin only packages
# ++ lib.optionals pkgs.stdenv.isDarwin [
#   m-cli
#   mas
# ]
