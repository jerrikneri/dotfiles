{ config, pkgs, lib, ... }:

{
  # services.xserver.enable = true;
  # services.xserver.windowManager.i3.enable = true;

  # programs.alacritty.enable = true;

  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # openldap and udisks test suites are flaky in sandboxed Nix builds
  # (need network, D-Bus, block devices). Disabling tests avoids
  # spurious build failures.
  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (old: {
        doCheck = false;
      });
      udisks = prev.udisks.overrideAttrs (old: {
        doCheck = false;
      });
    })
  ];
}

