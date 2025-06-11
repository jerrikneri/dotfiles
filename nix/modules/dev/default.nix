{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs
    yarn
  ];

shellHook = ''
  echo "Default dev shell"
'';
}

