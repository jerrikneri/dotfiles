{ config, pkgs, ... }:

{
  fonts = {
    enableDefaultFonts = true;

    packages = with pkgs; [
      pkgs.nerd-fonts.JetBrainsMono
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };
}

