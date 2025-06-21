{ pkgs, extraBuildInputs ? [ ], extraShellHook ? "" }:

# pkgs.mkShell {
#   buildInputs = with pkgs; [
#     php84Packages.composer
#     php84Extensions.imagick
#     php84Extensions.redis
#     php
#     phpactor
#     redis
#   ] ++ extraBuildInputs;
#
# shellHook = ''
#   echo "Php dev shell"
#   export PATH=${phpWithExtensions}/bin:$PATH
# '' + extraShellHook;
# }

let
  phpWithExtensions = pkgs.php.withExtensions (
    { enabled, all }:
    with all;
    enabled ++
    [
      imagick
      redis
    ]
  );
in
pkgs.mkShell {
  buildInputs = [
    phpWithExtensions
    pkgs.phpactor
    pkgs.php84Packages.composer
  ] ++ extraBuildInputs;

shellHook = ''
  echo "Php dev shell"
  zsh
'' + extraShellHook;
}
