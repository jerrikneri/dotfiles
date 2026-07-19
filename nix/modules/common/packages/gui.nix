{ pkgs, lib, isLinux, isDarwin, desktop, game, ... }:

{
  environment.systemPackages = with pkgs; [
    sniffnet
    # reserve for any GUI apps not in homebrew but available in nixpkgs
  ] ++ lib.optionals isDarwin [
    aerospace
  ] ++ lib.optionals (!pkgs.stdenv.isAarch64) [
  ] ++ lib.optionals isLinux [
    alacritty # Terminal
    ghostty
    gparted
    # librewolf # long compile times
    librewolf-bin
    # lmstudio # AI
  ] ++ lib.optionals (isLinux && desktop) [
    # -- desktop: move packages here --
    bruno
    godot
    # obsidian # allow unfree
    opensnitch
    rofi
    vscodium
    zeal # offline documentation
  ] ++ lib.optionals (isLinux && game) [
    # -- gaming: move packages here --
  ];
}

