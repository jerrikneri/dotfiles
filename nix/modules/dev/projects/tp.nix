{ pkgs }:

let
  baseShell = import ../php.nix { inherit pkgs; };
in
  baseShell // {
    buildInputs = baseShell.buildInputs ++ [
      pkgs.lazycli
      pkgs.lazyjournal
      pkgs.podman
    ];

    shellHook = baseShell.shellHook + ''
      echo "Project 1";
      tpp;
      sail up -d;
      sail npm i && sail npm run dev -d;
      n;
    '';
  }

