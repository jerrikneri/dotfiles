{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs
    npm
    yarn
  ];

shellHook = ''
  echo "Node dev shell"
'';
}

