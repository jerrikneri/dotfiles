{ config, pkgs, ... }:


  let
    dotfilesDir = builtins.path { name = "dotfiles"; path = ../../..; };
  in

  {
    # home.file.".zshrc".source = "${dotfilesDir}/.config/.zshrc";
    # home.file.".aliases".source = "${dotfilesDir}/.aliases/index";
    # home.file.".functions".source = "${dotfilesDir}/.functions/index";
    # home.file.".config".source = "${dotfilesDir}/.config";
    home.file = {
      # Symlink the whole .config directory
      ".config" = {
        source = "${dotfilesDir}/.config"; # Source folder
        recursive = true;  # Make sure it's recursive (this should be enabled by default for directories)
      };
    };
  }

