{ pkgs, lib, specialArgs ? {}, ... }:

let
  game = builtins.hasAttr "game" specialArgs && specialArgs.game;
in
{
  imports = [
    ../role.nix
    ./cli.nix
    ./tui.nix
    ./gui.nix
  ] ++ lib.optionals game [
    ./gaming.nix
  ];
}
