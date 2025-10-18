{ pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    alacritty # Terminal
    # anki # broken on darwin?
    bruno
    firefox
    # librewolf
    obsidian # allow unfree
    postman
    # vscode
    vscodium
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    aerospace
    stats
    tableplus # allow unsupported ?
    utm
  ] ++ lib.optionals (!pkgs.stdenv.isAarch64) [

  ] ++ lib.optionals isLinux [
    godot
    gparted
    orca-slicer
    pavucontrol # GUI to manage audio in PulseAudio / Pipewire
  ];
}

