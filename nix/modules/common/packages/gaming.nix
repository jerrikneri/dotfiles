{ pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    discord # allow unsupported
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
    rocmPackages.rocm-smi # System Management Interface for AMD GPU
    steam # x86 only?
    sunshine # NixOs Desktop Only
    vkbasalt
    vulkan-tools
    wineWowPackages.stableFull
  ];
}

