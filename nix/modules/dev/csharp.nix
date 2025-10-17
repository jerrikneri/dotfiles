
{ pkgs }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    # dotnet-sdk
    dotnet-sdk_9
  ];

shellHook = ''
  echo "C dev shell"
  zsh
'';
}

