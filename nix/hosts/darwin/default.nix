{ config, pkgs, ... }:

{
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

