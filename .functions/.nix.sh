nix-check-pkgs() {

  # nix-check-pkgs — verify that all given nixpkgs are available for a target architecture
  # Usage:
  #   nix-check-pkgs [architecture] pkg1 pkg2 pkg3
  # Example:
  #   nix-check-pkgs aarch64-darwin yazi lazygit

  set -euo pipefail

  PACKAGES=$(nix-installed)
  TARGET_ARCH="${1:-aarch64-darwin}"
  shift || true

  # Accept packages from args or from env var PACKAGES (if defined)
  if [ "$#" -gt 0 ]; then
    # use positional args as array
    PACKAGES=("$@")
  else
    # read nix-installed output into an array (one item per line)
    # mapfile -t PACKAGES < <(nix-installed)
    PACKAGES=()
    while IFS= read -r line; do
      PACKAGES+=("$line")
    done < <(nix-installed)
  fi

  echo "🔍 Checking nixpkgs for architecture: legacyPackages.$TARGET_ARCH"
  echo "-----------------------------------------------"

  unsupported=()

  for pkg in "${PACKAGES[@]}"; do
    echo -n "Checking $pkg... "

    # Try to evaluate the package for the target architecture
    # If it exists and is available, this will succeed
    if nix eval --raw "nixpkgs#legacyPackages.${TARGET_ARCH}.${pkg}.name" 2>/dev/null >/dev/null; then
      echo "✓ Supported"
    else
      echo "✗ Not supported"
      unsupported+=("$pkg")
    fi
  done

  echo "-----------------------------------------------"

  if [ "${#unsupported[@]}" -eq 0 ]; then
    echo "✅ All packages support $TARGET_ARCH"
  else
    echo "❌ These packages do NOT support $TARGET_ARCH:"
    for p in "${unsupported[@]}"; do
      echo "   - $p"
    done
    exit 2
  fi
}

nix-installed() {
  nix-config
  nix eval --json .\#darwinConfigurations.darwin.config.environment.systemPackages |
    jq -r '
    .[]
    | split("/")[-1]                         # take the basename
    | sub("^[^-]+-"; "")                     # remove store hash prefix
    | if test("-(bin|dev|lib|static|docs)?$") then .                    # skip pure suffix-only names
      elif test("-[0-9]+(\\.[0-9]+)*([a-z]*)?(-bin)?$") then sub("-[0-9]+(\\.[0-9]+)*([a-z]*)?(-bin)?$"; "")
      elif test("-[0-9]{4}-[0-9]{2}$") then sub("-[0-9]{4}-[0-9]{2}$"; "")  # e.g. nil-2025-06
      else .
      end
  '
}

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
  ln -sf "$DOTFILES_CONFIG/autostart" "$XDG_CONFIG_HOME/autostart"
}

nixu() {
  nix-config
  sudo nix flake update
}

nixs() {
  nix search nixpkgs $1
}

nhs() {
  nh search -P $1
}

nixsun() {
  sudo kill $(sudo ss -ltnp | awk '/:48010/ && /sunshine/ { match($NF, /pid=([0-9]+)/, a); print a[1] }')
  sunshine &
}
