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
}

nixd() {
  nix-config
  nix develop .\#$1
}
