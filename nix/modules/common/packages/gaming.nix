{ pkgs, config, lib, game ? false, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    # dxvk # included with wine?
  ] ++ lib.optionals (!pkgs.stdenv.isAarch64 && isLinux) [
    amdgpu_top # Tool to display AMDGPU usage
    bottles
    (pkgs.btop.overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or []) ++ [
        "-DBTOP_GPU=ON"
      ];
      buildInputs = old.buildInputs ++ [ pkgs.rocmPackages.rocm-smi ];
    }))
    gamemode
    lm_sensors
    lutris
    mangohud
    mesa # glxinfo
    moonlight-qt
    # obs-studio
    protontricks
    protonup-ng
    protonup-qt
    radeontop
    vkbasalt
    wineWowPackages.stableFull
  ] ++ lib.optionals (game) [
    discord # allow unsupported
    steam # x86 only?
  ];

  # Causes infinite recursion
  # programs = if isLinux then {
  #   steam.enable = if (!pkgs.stdenv.isAarch64 && game) then true else false;
  # } else {};

  programs.steam.enable = lib.mkIf (isLinux && !pkgs.stdenv.isAarch64 && game) true;


}

