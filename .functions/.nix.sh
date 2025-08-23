nixb() {
  nix-config
  source $SCRIPTS/get_os_variables.sh

  case "$os_name" in
  Darwin)
    echo "Detected macOS"
    sudo darwin-rebuild switch --flake .\#darwin
    ;;

  Linux)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      case "$ID" in
      nixos)
        echo "Detected NixOS"
        if [ $1 ]; then
          sudo nixos-rebuild switch --flake .\#nixos-$1
        else
          sudo nixos-rebuild switch --flake .\#nixos
        fi
        ;;
      *)
        echo "Linux distribution: $ID"
        sudo home-manager switch --flake .\#linux
        ;;
      esac
    else
      echo "Unsupported Linux distribution"
    fi
    ;;

  *)
    echo "Unsupported OS: $os_name"
    ;;
  esac

  echo "Running patches..."
  nix-patches
  echo "Done"
  cd -
}

nixd() {
  nix-config
  nix develop .\#$1
}

nix-del() {
  sudo nix-collect-garbage -d
}

# Symlinks and other patches until I figure out nix better
nix-patches() {
  ln -sf "$DOTFILES_CONFIG/tmux/plugins" "$XDG_CONFIG_HOME/tmux/plugins"
}

nixu() {
  nix-config
  sudo nix flake update
}

nixs() {
  nix search nixpkgs $1
}

nixsun() {
  sudo kill $(sudo ss -ltnp | awk '/:48010/ && /sunshine/ { match($NF, /pid=([0-9]+)/, a); print a[1] }')
  sunshine &
}
