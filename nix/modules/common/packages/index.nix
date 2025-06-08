{ pkgs, ... }:

{
  imports = [
    ./cli.nix
    ./gui.nix
    ./tui.nix
  ];
}
