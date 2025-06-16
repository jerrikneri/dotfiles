{ config, pkgs, ... }:

{
  programs = {
    neovim = {
      enable = true;
    };

    steam = {
       enable = if !pkgs.stdenv.isAarch64 then true else false;
    };

    zsh = {
        enable = true;
    };
  };
}
