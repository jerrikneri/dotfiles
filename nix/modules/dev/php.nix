{ pkgs, extraBuildInputs ? [ ], extraShellHook ? "" }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    php84Packages.composer
    php
    phpactor
  ] ++ extraBuildInputs;

shellHook = ''
  echo "Php dev shell"
'' + extraShellHook;
}

