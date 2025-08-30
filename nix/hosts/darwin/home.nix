{ config, pkgs, ... }:

  let
    dotfilesDir = builtins.path { name = "dotfiles"; path = ../../..; };
  in
  {
    # home.file.".aliases".source = "${dotfilesDir}/.aliases/index";
    # home.file.".functions".source = "${dotfilesDir}/.functions/index";
    # home.file = {
      # Symlink the whole .config directory
      # ".config" = {
        # source = "${dotfilesDir}/.config";
        # recursive = true;
      # };
      # ".zshenv".source = "${dotfilesDir}/.config/zsh/.zshenv";
    # };
    
    # home-manager.backupFileExtension = "home-manager-backup";
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        ignoreAllDups = true;
        ignorePatterns = ["rm *" "pkill *" "cp *"];
        path = "$HOME/.zsh_history";
        size = 10000;
        save = 10000;
        share = true;
      };
      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
          file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
        }
      ];
      initContent = ''
        echo "Initializing zsh from nix..."
        bindkey "''${key[Up]}" up-line-or-search
        echo "Done initializing zsh from nix..."
      '';
    };
  }

