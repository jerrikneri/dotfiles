{ pkgs, lib, specialArgs ? {}, ... }:

let
  game = builtins.hasAttr "game" specialArgs && specialArgs.game;
in
{
  imports = [
    ./cli.nix
    ./gui.nix
    ./tui.nix
  ] ++ lib.optionals game [
    ./gaming.nix
  ];
}

