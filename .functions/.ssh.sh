pve-update() {
  local hosts=("pve" "pve2" "pbs")

  for host in "${hosts[@]}"; do
    case "$host" in
      pve)  target="$ADMIN_USER@$PVE_HOST" ;;
      pve2) target="$ADMIN_USER@$PVE2_HOST" ;;
      pbs)  target="$ADMIN_USER@$PBS_HOST" ;;
    esac

    echo "--- Updating $host ($target) ---"
    ssh -t "$target" "apt-get update && apt-get upgrade -y && apt-get autoremove -y"
    echo ""
  done
}

s() {

  case "$1" in
  agh)
    ssh $ADMIN_USER@$AGH_HOST
    ;;
  bz)
    ssh $BAZZITE_USER@$BAZZITE_HOST
    ;;
  pve)
    ssh $ADMIN_USER@$PVE_HOST
    ;;
  pve2)
    ssh $ADMIN_USER@$PVE2_HOST
    ;;
  pbs)
    ssh $ADMIN_USER@$PBS_HOST
    ;;
  hl)
    ssh $ADMIN_USER@$HOMELAB_HOST
    ;;
  hp)
    ssh $ADMIN_USER@$HOMEPAGE_HOST
    ;;
  nix)
    ssh $MY_USER@$NIX_HOST
    ;;
  *)
    echo "Unsupported Host: $1"
    ;;
  esac
}

wake() {
  local target_name="$1"
  local port=9 # NixOS confirmed to work on port 9
  local target_mac=""
  local broadcast_ip="$VLAN_20"
  local jump_target="${M1_MAX_USER}@${M1_MAX_HOST}"

  if [ -z "$target_name" ] || [ "$target_name" = "--help" ]; then
    echo "Usage: wake <target>"
    echo "Available target:"
    echo " nix-server "
    echo " nix-gaming "
    return 0
  fi

  case "$target_name" in
  nix-gaming)
    target_max="${NIX_GAMING_MAC}"
    ;;
  nix-server)
    target_mac="${NIX_SERVER_MAC}"
    ;;
  *)
    echo "Unknown wake target: $target_name" >&2
    echo "Available target: nixos"
    return 1
    ;;
  esac

  echo "Waking $target_name via $jump_target..."
  ssh "$jump_target" "if command -v wakeonlan >/dev/null 2>&1; then wakeonlan -i '$broadcast_ip' -p '$port' '$target_mac'; else echo 'wakeonlan not installed on jump host' >&2; exit 127; fi"
}
