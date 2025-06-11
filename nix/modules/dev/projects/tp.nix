{ pkgs }:

import ../php.nix {
  inherit pkgs;
  extraBuildInputs = with pkgs; [
    lazycli
    lazyjournal
    podman
  ];

  extraShellHook = ''
    echo "Project 1";
    # Optional: comment these out if they’re too aggressive at shell startup
    # tpp
    # sail up -d
    # sail npm i && sail npm run dev -d
    # n
  '';
}


