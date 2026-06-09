{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python3
  ];

shellHook = ''
  echo "Python dev shell"
  zsh
'';
}

