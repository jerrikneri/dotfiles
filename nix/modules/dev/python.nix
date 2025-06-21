{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python3Full
  ];

shellHook = ''
  echo "Python dev shell"
  zsh
'';
}

