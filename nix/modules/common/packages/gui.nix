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
    vscode
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    aerospace
    karabiner-elements
    stats
    tableplus # allow unsupported ?
    utm
  ] ++ lib.optionals (!pkgs.stdenv.isAarch64) [

  ] ++ lib.optionals isLinux [
    godot
    gparted
    pavucontrol # GUI to manage audio in PulseAudio / Pipewire
  ];
}

