{ pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    alejandra # Uncompromising Nix Code Formatter
    bat # cat alternative
    bitwarden-cli
    claude-code
    cmatrix
    diff-so-fancy
    fastfetch
    ffmpeg
    fzf # Fuzzy Finder
    # intelli-shell
    neovim
    nh # yet another nix helper
    nix-output-monitor
    nvd # nix diff
    gcc
    git
    nil # Nix Language Server
    nixd # Nix LSP
    pciutils # lspci
    ripgrep # Grep alternative
    shellcheck # Linter for shell commands
    tailscale
    tmux
    # tmuxPlugins.copycat
    # tmuxPlugins.sensible
    # vimPlugins.vim-tmux
    # vimPlugins.vim-tmux-focus-events
    # tmuxPlugins.vim-tmux-focus-events
    # tmuxPlugins.vim-tmux-navigator
    tmuxinator
    tree
    #vimPlugins.LazyVim
    wget
    # wl-clipboard # Wayland
    xan # CSV Magician
    xclip
    yt-dlp
    zoxide
    zsh-syntax-highlighting
    zsh-vi-mode
    zsh # Shell
  ] ++ lib.optionals isLinux [
    alsa-utils # Advanced Linux Sound Architecture
    distrobox
    pulseaudioFull
    vkd3d
    xclip
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    atuin
    phpactor
  ];
}
