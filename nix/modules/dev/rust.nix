{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    rustup
  ];

shellHook = ''
  echo "Rust dev shell"
  zsh
'';
}

