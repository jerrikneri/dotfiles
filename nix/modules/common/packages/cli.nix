{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alejandra # Uncompromising Nix Code Formatter
    bat # cat alternative
    diff-so-fancy
    distrobox
    fzf # Fuzzy Finder
    neovim
    git
    nil # Nix Language Server
    ripgrep # Grep alternative
    tmux
    #vimPlugins.LazyVim
    wget
    zsh-syntax-highlighting
    zsh-vi-mode
    zsh # Shell
  ];
}

