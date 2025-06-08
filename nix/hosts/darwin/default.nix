{ config, pkgs, ... }:

{
  # May be only for a specific error to the host I tested this on.
  ids.gids.nixbld = 350;

  users.users.kgh = {
    name = "kgh";
    home = "/Users/kgh";
  };

  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

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

