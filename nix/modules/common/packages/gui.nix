{ pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    alacritty # Terminal
    # anki # broken on darwin?
    bruno
    firefox
    obsidian # allow unfree
    tableplus # allow unsupported ?
    vscode
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    aerospace
    karabiner-elements
    stats
    utm
  ] ++ lib.optionals (!pkgs.stdenv.isAarch64) [

  ] ++ lib.optionals isLinux [

  ];
}

