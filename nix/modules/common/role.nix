{ pkgs, lib, specialArgs ? {}, ... }:
{
  _module.args = {
    isLinux = pkgs.stdenv.isLinux;
    isDarwin = pkgs.stdenv.isDarwin;
    isArm = pkgs.stdenv.isAarch64;
    game = builtins.hasAttr "game" specialArgs && specialArgs.game;
    desktop = builtins.hasAttr "desktop" specialArgs && specialArgs.desktop;
  };
}
