{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gcc
    glibc
  ];

shellHook = ''
  echo "C dev shell"
  zsh
'';
}

