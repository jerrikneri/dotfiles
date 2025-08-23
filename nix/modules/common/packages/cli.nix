{ pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    alejandra # Uncompromising Nix Code Formatter
    bat # cat alternative
    cmatrix
    diff-so-fancy
    fzf # Fuzzy Finder
    neovim
    gcc
    git
    nil # Nix Language Server
    pciutils # lspci
    ripgrep # Grep alternative
    tailscale
    tmux
    # tmuxPlugins.copycat
    # tmuxPlugins.sensible
    # vimPlugins.vim-tmux
    # vimPlugins.vim-tmux-focus-events
    # tmuxPlugins.vim-tmux-focus-events
    # tmuxPlugins.vim-tmux-navigator
    tmuxinator
    #vimPlugins.LazyVim
    wget
    # wl-clipboard # Wayland
    xclip
    zoxide
    zsh-syntax-highlighting
    zsh-vi-mode
    zsh # Shell
  ] ++ lib.optionals isLinux [
    alsa-utils # Advanced Linux Sound Architecture
    distrobox
    pulseaudioFull
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    atuin
  ];
}
