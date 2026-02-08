{ pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    sniffnet
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # reserve for any GUI apps not in homebrew but available in nixpkgs
  ] ++ lib.optionals (!pkgs.stdenv.isAarch64) [

  ] ++ lib.optionals isLinux [
    alacritty # Terminal
    bruno
    firefox
    freetube
    godot
    gparted
    librewolf
    lmstudio # AI
    obsidian # allow unfree
    orca-slicer
    opensnitch
    pavucontrol # GUI to manage audio in PulseAudio / Pipewire
    postman
    rofi
    vscodium
    zeal # offline documentation
  ];
}

