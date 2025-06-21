{ pkgs }:

import ../php.nix {
  inherit pkgs;
  extraBuildInputs = with pkgs; [
    # Find actual pkgs that are relevant
    docker
    lazycli
    lazyjournal
    podman
  ];

  extraShellHook = ''
    echo "TP Project";
    zsh
  '';
}


