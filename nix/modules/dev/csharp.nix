
{ pkgs }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    dotnet-sdk
  ];

shellHook = ''
  echo "C dev shell"
  zsh
'';
}

