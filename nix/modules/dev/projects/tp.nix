{ pkgs }:

import ../php.nix {
  inherit pkgs;
  extraBuildInputs = with pkgs; [
    # Find actual pkgs that are relevant
    lazycli
    lazyjournal
    podman
  ];

  extraShellHook = ''
    echo "TP Project";
    zsh
    tpp
    gpl
    sail up -d
    sail npm i && sail npm run dev -d
    n
  '';
}


