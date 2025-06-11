{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python
  ];

shellHook = ''
  echo "Python dev shell"
'';
}

