
{ pkgs, config, lib, ... }@args:

let
  game = args.game ? false;
  isLinux = pkgs.stdenv.isLinux;
in
{
  imports = [
    ./cli.nix
    ./gui.nix
    ./tui.nix
  ] ++ lib.optionals (game && isLinux) [
    ./gaming.nix
  ];
}

