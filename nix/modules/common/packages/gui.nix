{ pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # reserve for any GUI apps not in homebrew but available in nixpkgs
  ] ++ lib.optionals (!pkgs.stdenv.isAarch64) [

  ] ++ lib.optionals isLinux [
    alacritty # Terminal
    bruno
    firefox
    godot
    gparted
    librewolf
    obsidian # allow unfree
    orca-slicer
    pavucontrol # GUI to manage audio in PulseAudio / Pipewire
    postman
    vscodium
    zeal # offline documentation
  ];
}

