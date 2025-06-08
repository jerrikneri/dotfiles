{ config, pkgs, ... }:

  let
    dotfilesDir = builtins.path { name = "dotfiles"; path = ../../..; };
  in
  {
    # home.file.".aliases".source = "${dotfilesDir}/.aliases/index";
    # home.file.".functions".source = "${dotfilesDir}/.functions/index";
    home.file = {
      # Symlink the whole .config directory
      ".config" = {
        source = "${dotfilesDir}/.config";
        recursive = true;
      };
    };
  }

