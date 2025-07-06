{ pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    alacritty # Terminal
    # anki # broken on darwin?
    bruno
    # discord # allow unsupported
    firefox
    moonlight-qt
    obsidian # allow unfree
    # tableplus # allow unsupported ?
    vscode
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    aerospace
    karabiner-elements
    stats
    utm
  ] ++ lib.optionals (!pkgs.stdenv.isAarch64) [
    steam # x86 only?
  ] ++ lib.optionals isLinux [
    protonup-qt
  ];
}

