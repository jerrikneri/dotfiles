{ pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in {
  environment.systemPackages = with pkgs; [
    discord # allow unsupported
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
    mesa-demos # glxinfo
    moonlight-qt
    protontricks
    protonup-qt
    radeontop
    steam # x86 only?
    vkbasalt
  ];
}

