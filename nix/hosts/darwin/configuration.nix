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

  # May be only for a specific error to the host I tested this on.
  ids.gids.nixbld = 350;

  users.users.kgh = {
    name = "kgh";
    home = "/Users/kgh";
  };

  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  # TODO duplicated here and in configuration.nix, extract?
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  system.stateVersion = 4;

  system.defaults = {
    dock = {
      autohide = true;
      showhidden = true;
      orientation = "left"; # or "bottom", "right"
      tilesize = 36;
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
    };
  };
}
