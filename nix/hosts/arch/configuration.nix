{ config, pkgs, ... }:

{
  home.username = "kgh";
  home.homeDirectory = "/home/kgh";

  programs.home-manager.enable = true;
}

