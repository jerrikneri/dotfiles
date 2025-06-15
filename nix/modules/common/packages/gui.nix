{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty # Terminal
    anki
    bruno
    # discord # allow unsupported
    firefox
    moonlight-qt
    obsidian # allow unfree
    # steam // x86 only?
    # tableplus // allow unsupported ?
    vscode
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    aerospace
    karabiner-elements
    lulu
    stats
    utm
  ];
}

