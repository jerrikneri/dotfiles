{ pkgs, lib, config, ... }: {

  options = {
    commonPackages.enable = 
      lib.mkEnableOption "enables common packages";
  };

  config = lib.mkIf config.commonPackages.enable {
    option1 = 5;
    option2 = true;
  };



  }

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  }

  outputs = { self, nixpkgs }:
  let
    system = "aarch64-darwin"
    pkgs = [
        pkgs.alacritty
        pkgs.bat
        pkgs.btop
        pkgs.diff-so-fancy
        pkgs.fzf
        pkgs.lazydocker
        pkgs.lazygit
        pkgs.lazysql
        pkgs.neovim
        pkgs.newsboat
        pkgs.phpactor
        pkgs.posting
        pkgs.ripgrep
        pkgs.tmux
        pkgs.zsh-syntax-highlighting
        pkgs.zsh-vi-mode
    ]
  in
  {
    packages.${sysytem}.
  }
}
