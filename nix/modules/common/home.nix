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
      ".zshenv".source = "${dotfilesDir}/.config/zsh/.zshenv";
    };

    home.file.".config/powermanagementprofilesrc".text = ''
      [AC]
      icon=ac-adapter
      name=AC
      powerProfile=performance

      [Battery]
      icon=battery
      name=Battery
      powerProfile=performance

      [LowBattery]
      icon=battery-low
      name=Low Battery
      powerProfile=performance

      [BrightnessControl]
      idleTimeout=0

      [ScreenBrightness]
      idleTimeout=0

      [HandleButtonEvents]
      lidAction=0
      powerButtonAction=0
      suspendButtonAction=0

      [SuspendSession]
      idleTime=0
      suspendThenHibernate=false
      suspendType=0
    '';


  }

