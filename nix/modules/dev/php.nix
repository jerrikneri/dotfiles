{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    php84Packages.composer
    php
    phpactor
  ];

shellHook = ''
  echo "Php dev shell"
'';
}

