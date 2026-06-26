{ config, pkgs, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # max-jobs and cores set per-host
      max-substitution-jobs = 4;
      keep-failed = true;
      keep-going = true;
      # build-dir removed: /var/tmp is 1777 world-writable, Nix sandbox rejects it
      # defaults to /tmp which Nix handles fine
      extra-substituters = [
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
