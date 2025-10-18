{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    bash
    dialog
    zsh
  ];

shellHook = ''
  echo "Linux Shell Scripting"
  zsh
  cd $DOTFILES/bin
'';
}

