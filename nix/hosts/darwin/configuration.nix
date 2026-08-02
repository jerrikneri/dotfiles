# Should this be named configuration.nix ?
{ config, pkgs, ... }:

let
  homebrewPkgs = import ../../modules/common/packages/brew.nix;
in {
  homebrew = {
    enable = true;

    brews = homebrewPkgs.brews;
    casks = homebrewPkgs.casks;
    taps = homebrewPkgs.taps;
  };

  # home-manager = {
  #   backupFileExtension = "home-manager-backup";
  #   users.jan = {
  #     imports = [
  #       ./home.nix
  #     ];
  #     home.stateVersion = "25.11";
  #   };
  # };

  # May be only for a specific error to the host I tested this on.
  ids.gids.nixbld = 350;

  users.users.jan = {
    name = "jan";
    home = "/Users/jan";
    shell = pkgs.zsh;
  };

  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;
  programs.zsh.histFile = "$HOME/.config/zsh/.zhistory";
  programs.zsh.histSize = 50000;
  programs.zsh.shellInit = ''
    source ~/code/dotfiles/.scripts/utils.sh
    _debug_echo "Shell Init NIXOS"
    source ~/.zshenv
    # This sources .zshrc twice, but seems necessary for zsh history while not migrating .zshrc to nix way
    source ~/.config/zsh/.zshrc
  '';

  # TODO duplicated here and in configuration.nix, extract?
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  system.stateVersion = 4;

  system.defaults = {
    dock = {
      autohide = true;
      autohide-time-modifier = 0.0;
      autohide-delay = 0.0;
      minimize-to-application = true;
      showhidden = true;
      orientation = "right"; # "left", "bottom", "right"
      tilesize = 75;
      expose-animation-duration = 0.0;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # or "Light"
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticWindowAnimationsEnabled = false;
      NSScrollAnimationEnabled = false;
      NSWindowResizeTime = 0.001;
    };
  };

  system.activationScripts.disableAnimations.text = ''
    defaults write NSGlobalDomain QLPanelAnimationDuration -float 0
    defaults write NSGlobalDomain NSToolbarFullScreenAnimationDuration -float 0
    defaults write NSGlobalDomain NSBrowserColumnAnimationSpeedMultiplier -float 0
    defaults write NSGlobalDomain NSDocumentRevisionsWindowTransformAnimation -bool false
    defaults write NSGlobalDomain NSScrollViewRubberbanding -bool false
    defaults write com.apple.finder DisableAllAnimations -bool true
    defaults write com.apple.mail DisableSendAnimations -bool true
    defaults write com.apple.mail DisableReplyAnimations -bool true
    defaults write com.apple.dock springboard-show-duration -float 0
    defaults write com.apple.dock springboard-hide-duration -float 0
    defaults write com.apple.dock springboard-page-duration -float 0
  '';
}
