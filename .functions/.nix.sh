nixb() {
  nix-config
  source $SCRIPTS/get_os_variables.sh

  case "$os_name" in
  Darwin)
    echo "Detected macOS"
    sudo nixos-rebuild switch --flake .\#nixos
    ;;

  Linux)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      case "$ID" in
      nixos)
        echo "Detected NixOS"
        sudo nixos-rebuild switch --flake .\#nixos
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
