{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ffmpeg
  ];

shellHook = ''
  echo "Multimedia shell"
  zsh
'';
}

