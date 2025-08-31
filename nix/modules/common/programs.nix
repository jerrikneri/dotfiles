{ config, pkgs, ... }:

{
  programs = {
    neovim = {
      enable = true;
    };

    zsh = {
        enable = true;
    };
  };
}
