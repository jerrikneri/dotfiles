{ pkgs, ... }:

{
  imports = [
    ./cli.nix
    # ./gaming.nix
    ./gui.nix
    ./tui.nix
  ];
}
