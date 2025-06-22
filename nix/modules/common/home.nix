{ config, pkgs, ... }:

  let
    dotfilesDir = builtins.path {
      name = "dotfiles";
      path = ../../..;
      filter = path: type: true; # Disable filtering, include .gitignore files.
    };
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
      ".config/tmux/plugins" = {
        source = "${dotfilesDir}/.config/tmux/plugins";
        recursive = true;
      };
      ".zshenv".source = "${dotfilesDir}/.config/zsh/.zshenv";
    };
  }

