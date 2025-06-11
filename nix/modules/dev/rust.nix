{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    rust
  ];

shellHook = ''
  echo "Rust dev shell"
'';
}

