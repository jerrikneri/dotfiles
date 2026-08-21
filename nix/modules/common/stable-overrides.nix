{ config, lib, specialArgs ? {}, ... }:
let
  stable = specialArgs.stablePkgs or null;
in
{
  options.dotfiles.stableOverrides = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "librewolf-bin" "tailscale" "bitwarden-cli" "opensnitch" ];
    example = [ "bottles" ];
    description = ''
      Top-level package names to pull from nixpkgs-stable (nixos-26.05)
      instead of nixpkgs-unstable, so they receive stable-channel vetting
      and security backports without pulling brand-new upstream releases.
      Defaults pin security-sensitive leaf applications. Setting this list
      per-host replaces the default. Only list leaf applications (not shared
      libraries like curl/openssl) to avoid forcing wide rebuilds of
      dependent packages.
    '';
  };

  config = lib.mkIf (stable != null && config.dotfiles.stableOverrides != []) {
    nixpkgs.overlays = [
      (final: prev:
        builtins.listToAttrs (map (name:
          lib.nameValuePair name stable.${name}
        ) config.dotfiles.stableOverrides)
      )
    ];
  };
}
