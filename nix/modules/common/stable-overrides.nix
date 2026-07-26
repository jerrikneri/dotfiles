{ config, lib, specialArgs ? {}, ... }:
let
  stable = specialArgs.stablePkgs or null;
in
{
  options.dotfiles.stableOverrides = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    example = [ "bottles" ];
    description = ''
      Top-level package names to pull from nixpkgs-stable (nixos-26.05)
      instead of nixpkgs-unstable. Example: ["bottles"]
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
