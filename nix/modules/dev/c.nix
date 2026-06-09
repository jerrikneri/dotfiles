{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gcc
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    glibc
  ];

  shellHook = ''
    echo "C dev shell"
    zsh
  '';
}

