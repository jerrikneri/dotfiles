backup-packages() {
  cd $DOTFILES/arch

  mv packages packages.bkup
  mv pacmans pacmans.bkup
  mv yays yays.bkup

  pacman -Q | awk '{print $1}' >pacmans
  yay -Qm | awk '{print $1}' >yays

  cat pacmans >packages
  cat yays >>packages
}

install-packages() {
  cd $DOTFILES/arch
  yay -S --needed - <packages
}
