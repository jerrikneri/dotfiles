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

  local timestamp git_head artifacts_dir host_name flake_ref log_dir log_file
  local build_start build_end build_duration build_exit=0
  local prev_gen new_gen

  timestamp=$(date +"%Y-%m-%d-%H%M")
  git_head=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  artifacts_dir="$DOTFILES/nix/workspace/artifacts"

  case "$os_name" in
  Darwin)
    host_name="darwin"
    flake_ref=".#darwin"
    ;;
  Linux)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      case "$ID" in
      nixos)
        if [ "$1" ]; then
          host_name="nixos-$1"
          flake_ref=".#nixosConfigurations.nixos-$1"
        else
          host_name="nixos"
          flake_ref=".#nixosConfigurations.nixos"
        fi
        ;;
      *)
        host_name="$ID"
        flake_ref=".#linux"
        ;;
      esac
    else
      host_name="unknown-linux"
      flake_ref=""
    fi
    ;;
  *)
    host_name="unknown"
    flake_ref=""
    ;;
  esac

  log_dir="$artifacts_dir/$host_name"
  mkdir -p "$log_dir"
  log_file="$log_dir/$timestamp.log"

  # --- Pre-build artifact header ---
  {
    echo "# Build Log: $host_name"
    echo "# Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Git HEAD: $git_head"
    echo "# User: $(whoami)@$(hostname -s 2>/dev/null || echo unknown)"
    echo ""

    if [ -f "$log_dir/latest" ]; then
      prev_gen=$(cat "$log_dir/latest" 2>/dev/null)
      if [ -n "$prev_gen" ]; then
        echo "# Previous build gen: $prev_gen"
      fi
    fi

    if command -v nixos-version &>/dev/null; then
      echo "# Pre-build system: $(nixos-version 2>/dev/null || echo unknown)"
    fi

    echo ""
    echo "## Recent Commits"
    echo '```'
    git log --oneline -5 2>/dev/null || echo "(not a git repo)"
    echo '```'
    echo ""

    echo "## Uncommitted Changes"
    echo '```'
    git diff --stat 2>/dev/null || echo "(not a git repo)"
    echo '```'
    echo ""

    echo "## Build Output"
    echo '```'
  } > "$log_file"

  # --- Run the build ---
  build_start=$(date +%s)

  case "$os_name" in
  Darwin)
    echo "Detected macOS"
    nh darwin switch "$flake_ref" 2>&1 | tee -a "$log_file"
    build_exit=${pipestatus[1]}
    ;;
  Linux)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      case "$ID" in
      nixos)
        echo "Detected NixOS ($host_name)"
        nh os switch "$flake_ref" 2>&1 | tee -a "$log_file"
        build_exit=${pipestatus[1]}
        ;;
      *)
        echo "Detected Linux ($ID)"
        sudo home-manager switch --flake .\#linux 2>&1 | tee -a "$log_file"
        build_exit=${pipestatus[1]}
        ;;
      esac
    else
      echo "Unsupported Linux distribution" | tee -a "$log_file"
      build_exit=1
    fi
    ;;
  *)
    echo "Unsupported OS: $os_name" | tee -a "$log_file"
    build_exit=1
    ;;
  esac

  build_end=$(date +%s)
  build_duration=$((build_end - build_start))

  # --- Post-build artifact footer ---
  {
    echo '```'
    echo ""
    echo "## Build Result"
    echo "- Exit code: $build_exit"
    echo "- Duration: ${build_duration}s"
    echo "- Ended: $(date '+%Y-%m-%d %H:%M:%S')"

    if [ -f /run/current-system ]; then
      new_gen=$(readlink -f /run/current-system 2>/dev/null)
      if [ -n "$new_gen" ]; then
        echo "- Generation: $new_gen"
        echo "$new_gen" > "$log_dir/latest"
      fi
    fi

    if [ -n "$prev_gen" ] && [ -d "$prev_gen" ] && [ -n "$new_gen" ] && [ -d "$new_gen" ]; then
      echo ""
      echo "## Store Diff (vs previous)"
      echo '```'
      nix store diff-closures "$prev_gen" "$new_gen" 2>/dev/null || echo "(nix store diff-closures not available)"
      echo '```'
    fi
  } >> "$log_file"

  echo ""

  # --- Summary ---
  if [ -n "$prev_gen" ] && [ -f /run/current-system ]; then
    echo "--- Build Summary ---"
    echo "Host:       $host_name"
    echo "Git:        $git_head"
    echo "Duration:   ${build_duration}s"
    echo "Exit:       $build_exit"
    echo "Log:        $log_file"
    if [ -n "$new_gen" ]; then
      echo "Generation: $new_gen"
    fi
    if [ -d "${prev_gen:-}" ] && [ -d "${new_gen:-}" ]; then
      echo ""
      echo "Changed paths:"
      nix store diff-closures "$prev_gen" "$new_gen" 2>/dev/null | head -30 || echo "(diff not available)"
    fi
    echo "---"
  fi

  echo ""
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
  nh search -P $1
  # Doesn't show supported architecture
  # nix search nixpkgs $1
}

nhs() {
  nh search -P $1
}

nixe() {
  local host_suffix="${1}"
  local action="${2:-check}"
  local extra_arg="${3:-}"

  if [ -z "$host_suffix" ]; then
    echo "Usage: nixe <host> [action] [arg]"
    echo "  nixe game                quick config eval check"
    echo "  nixe game warnings       show config warnings"
    echo "  nixe game pkg            list systemPackages"
    echo "  nixe game svc <name>     show service config"
    echo "  nixe game <attr-path>    eval arbitrary config attr"
    echo "  nixe game dry            dry-run build stats"
    echo "  nixe game full           full pre-push check"
    echo ""
    echo "  Hosts: nixos, game, pve, utm"
    return 1
  fi

  nix-config

  local host
  case "$host_suffix" in
    nixos) host="nixos" ;;
    game)  host="nixos-game" ;;
    pve)   host="nixos-pve" ;;
    utm)   host="nixos-utm" ;;
    *)     host="$host_suffix" ;;
  esac

  local flake_ref=".#nixosConfigurations.$host"
  local system="x86_64-linux"
  local toplevel="$flake_ref.config.system.build.toplevel"

  case "$action" in
    check)
      echo -n "$host: "
      local result
      result=$(nix eval --impure "$toplevel.drvPath" --system "$system" 2>&1)
      if echo "$result" | grep -q '/nix/store'; then
        echo "OK"
      else
        echo "FAIL"
        echo "$result" | grep -v warning | tail -5
        return 1
      fi
      ;;

    warnings)
      echo -n "$host warnings: "
      nix eval --impure "$flake_ref.config.warnings" --system "$system" --json 2>/dev/null
      ;;

    pkg|packages)
      nix eval --impure "$flake_ref.config.environment.systemPackages" --system "$system" --json 2>/dev/null \
        | python3 -c "
import json, sys
pkgs = json.load(sys.stdin)
for p in sorted(set(pkgs)):
    name = p.split('/')[-1][33:]
    for s in ['-bin', '-dev', '-lib', '-static', '-docs']:
        if name.endswith(s):
            name = name[:-len(s)]
            break
    print(name)
"
      ;;

    svc|service)
      if [ -z "$extra_arg" ]; then
        echo "Usage: nixe $host_suffix svc <service-name>"
        return 1
      fi
      nix eval --impure "$flake_ref.config.systemd.services.$extra_arg" --system "$system" 2>&1 | grep -v warning
      ;;

    dry)
      nix build --dry-run "$toplevel" --system "$system" 2>&1 | grep -E 'will be (built|fetched)'
      ;;

    full)
      echo "=== $host ==="
      echo -n "  eval: "
      local r
      r=$(nix eval --impure "$toplevel.drvPath" --system "$system" 2>&1)
      if echo "$r" | grep -q '/nix/store'; then
        echo "OK"
      else
        echo "FAIL"
        echo "$r" | grep -v warning | tail -3
      fi
      echo -n "  warnings: "
      nix eval --impure "$flake_ref.config.warnings" --system "$system" --json 2>/dev/null
      echo -n "  packages: "
      nix eval --impure "$flake_ref.config.environment.systemPackages" --system "$system" --json 2>/dev/null \
        | python3 -c "import json,sys; print(len(set(json.load(sys.stdin))))"
      ;;

    *)
      # Treat as arbitrary attr path
      nix eval --impure "$flake_ref.config.$action" --system "$system" 2>&1 | grep -v warning
      ;;
  esac

  cd - > /dev/null
}

nix-diff-hosts() {
  local host1="${1:-nixos}"
  local host2="${2:-nixos-game}"
  local attr="${3:-systemd.services.sunshine}"
  local mode="${4:-}"
  local system="${5:-x86_64-linux}"

  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required. Install with: nix profile install nixpkgs#jq"
    return 1
  fi

  nix-config 2>/dev/null || true

  if [ "$mode" = "--packages" ]; then
    diff \
      <(nix eval --impure ".#nixosConfigurations.$host1.config.$attr" --json --system "$system" 2>/dev/null \
        | python3 -c "
import json, sys
pkgs = json.load(sys.stdin)
for p in sorted(set(pkgs)):
    name = p.split('/')[-1][33:]
    # strip common suffixes for cleaner diff
    for s in ['-bin', '-dev', '-lib', '-static', '-docs']:
        if name.endswith(s):
            name = name[:-len(s)]
            break
    print(name)
") \
      <(nix eval --impure ".#nixosConfigurations.$host2.config.$attr" --json --system "$system" 2>/dev/null \
        | python3 -c "
import json, sys
pkgs = json.load(sys.stdin)
for p in sorted(set(pkgs)):
    name = p.split('/')[-1][33:]
    for s in ['-bin', '-dev', '-lib', '-static', '-docs']:
        if name.endswith(s):
            name = name[:-len(s)]
            break
    print(name)
")
  else
    local r1 r2
    r1=$(nix eval --impure ".#nixosConfigurations.$host1.config.$attr" --json --system "$system" 2>&1)
    r2=$(nix eval --impure ".#nixosConfigurations.$host2.config.$attr" --json --system "$system" 2>&1)

    if echo "$r1" | grep -q 'error:'; then
      echo "FAIL $host1: $(echo "$r1" | tail -3)"
      return 1
    fi
    if echo "$r2" | grep -q 'error:'; then
      echo "FAIL $host2: $(echo "$r2" | tail -3)"
      return 1
    fi

    echo "=== $host1 ==="
    echo "$r1" | jq -S . 2>/dev/null || echo "$r1"
    echo ""
    echo "=== $host2 ==="
    echo "$r2" | jq -S . 2>/dev/null || echo "$r2"
    echo ""

    if [ "$r1" = "$r2" ]; then
      echo "IDENTICAL"
    else
      echo "DIFFERENT:"
      diff <(echo "$r1" | jq -S . 2>/dev/null) <(echo "$r2" | jq -S . 2>/dev/null) || true
    fi
  fi
}

nixsun() {
  sudo kill $(sudo ss -ltnp | awk '/:48010/ && /sunshine/ { match($NF, /pid=([0-9]+)/, a); print a[1] }')
  sunshine &
}

sun-pin() {
  if [ -z "$1" ]; then
    echo "Usage: sun-pin <4-digit-pin>"
    return 1
  fi
  if [ -z "$SUNSHINE_PASSWORD" ]; then
    echo "SUNSHINE_PASSWORD not set in .env"
    return 1
  fi
  curl -k -u "sunshine:$SUNSHINE_PASSWORD" \
    -X POST https://localhost:47990/api/pin \
    -H "Content-Type: application/json" \
    -d "{\"pin\": \"$1\"}"
}
