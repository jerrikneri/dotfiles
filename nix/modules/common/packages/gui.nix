{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty # Terminal
    anki
    bruno
    discord
    firefox
    moonlight-qt
    obsidian
    steam
    tableplus
    vscode
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    aerospace
    karabiner-elements
    lulu
    stats
    utm
  ]
}

