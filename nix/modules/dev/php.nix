{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    php
    phpactor
  ];

shellHook = ''
  echo "Php dev shell"
'';
}

