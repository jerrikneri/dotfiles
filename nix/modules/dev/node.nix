{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs
    yarn
  ];

shellHook = ''
  echo "Node dev shell"
  zsh
'';
}

