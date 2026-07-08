{ pkgs, lib, isLinux, isArm, game, ... }:

{
  environment.systemPackages = with pkgs; [
    # dxvk # included with wine?
  ] ++ lib.optionals (!isArm && isLinux) [
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
    # mangohud # sometimes interferes with lutris installs
    mesa # glxinfo
    moonlight-qt
    # obs-studio
    protontricks
    protonup-ng
    protonup-qt
    radeontop
    vkbasalt
    winetricks
    #wineWowPackages.stableFull
    # wineWow64Packages.stableFull
  ] ++ lib.optionals (game) [
    discord # allow unsupported
    # steam # x86 only? programs.steam.enable covers this
  ];

  # Causes infinite recursion
  # programs = if isLinux then {
  #   steam.enable = if (!pkgs.stdenv.isAarch64 && game) then true else false;
  # } else {};

  # programs.steam.enable = lib.mkIf (isLinux && !pkgs.stdenv.isAarch64 && game) true;

  programs.steam = lib.mkIf (isLinux && !isArm && game) {
    enable = true;

    # These handle the Steam Remote Play and LAN library sharing ports
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  networking.firewall = lib.mkIf (isLinux && !isArm && game) {
    # Allow Steam LAN game transfers (local content cache)
    allowedTCPPortRanges = [
      { from = 27031; to = 27036; }
    ];
    allowedUDPPortRanges = [
      { from = 27031; to = 27036; }
    ];
  };

  # Nice to have for LAN discovery (mDNS / Avahi)
  services.avahi = lib.mkIf (isLinux && game) {
    enable = true;
    nssmdns4 = true;
  };

  hardware.graphics = lib.mkIf (isLinux && game) {
    enable = true;
    enable32Bit = true;
  };
}

