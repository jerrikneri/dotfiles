{ pkgs, lib, isLinux, isDarwin, desktop, game, ... }:

{
  environment.systemPackages = with pkgs; [
    alejandra # Uncompromising Nix Code Formatter
    bat # cat alternative
    bats # Bash Automated Testing System
    bitwarden-cli
    cmatrix
    diff-so-fancy
    fastfetch
    ffmpeg
    fzf # Fuzzy Finder
    gh # git hub cli, for gh-dash
    glow
    # intelli-shell
    # llama-cpp
    neovim
    nh # yet another nix helper
    nix-output-monitor
    nvd # nix diff
    gcc
    git
    mcat
    nil # Nix Language Server
    nixd # Nix LSP
    opencode
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
    wakeonlan
    wget
    # wl-clipboard # Wayland
    xan # CSV Magician
    xclip
    yt-dlp
    zoxide
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-syntax-highlighting
    zsh-vi-mode
    zsh # Shell
  ] ++ lib.optionals isLinux [
    alsa-utils # Advanced Linux Sound Architecture
    distrobox
    pulseaudioFull
    vkd3d
    xclip
  ] ++ lib.optionals isDarwin [
    android-tools
    atuin
    # claude-code
    phpactor
  ] ++ lib.optionals (isLinux && desktop) [
    # -- desktop: move packages here --
  ] ++ lib.optionals (isLinux && game) [
    # -- gaming: move packages here --
  ];
}
