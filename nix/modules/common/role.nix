{ pkgs, lib, specialArgs ? {}, ... }:
{
  _module.args = {
    isLinux = pkgs.stdenv.hostPlatform.isLinux;
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    isArm = pkgs.stdenv.hostPlatform.isAarch64;
    game = builtins.hasAttr "game" specialArgs && specialArgs.game;
    desktop = builtins.hasAttr "desktop" specialArgs && specialArgs.desktop;
  };
}
