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
    bruno
    firefox
    freetube
    godot
    gparted
    # librewolf # long compile times
    # lmstudio # AI
    obsidian # allow unfree
    orca-slicer
    opensnitch
    pavucontrol # GUI to manage audio in PulseAudio / Pipewire
    postman
    rofi
    vscodium
    zeal # offline documentation
  ] ++ lib.optionals (isLinux && desktop) [
    # -- desktop: move packages here --
  ] ++ lib.optionals (isLinux && game) [
    # -- gaming: move packages here --
  ];
}

