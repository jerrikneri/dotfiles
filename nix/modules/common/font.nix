{ config, pkgs, ... }:

{
  fonts = {
    enableDefaultFonts = true;

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      # (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };
}

