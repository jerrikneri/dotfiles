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

wake-list() {
  cat <<'EOF'
Available wake targets:
  test-bazzite
  home-server
  proxmox-amd
EOF
}

wake() {
  local target_name="$1"
  local port="${2:-9}"
  local target_mac=""
  local broadcast_ip=""
  local jump_target=""

  if [ -z "$target_name" ] || [ "$target_name" = "--list" ]; then
    wake-list
    return 0
  fi

  jump_target="${M1_MAX_USER}@${M1_MAX_HOST}"

  case "$target_name" in
  test-bazzite)
    target_mac="$BAZZITE_MAC"
    broadcast_ip="${BAZZITE_HOST}"
    ;;
  home-server)
    target_mac="$HOME_SERVER_MAC"
    broadcast_ip="${HOME_SERVER_BROADCAST_IP:-192.168.20.255}"
    ;;
  proxmox-amd)
    target_mac="$PROXMOX_MA"
    broadcast_ip="${PROXMOX_BROADCAST_IP:-192.168.20.255}"
    ;;
  *)
    echo "Unknown wake target: $target_name" >&2
    wake-list
    return 1
    ;;
  esac

  if [ -z "$target_mac" ]; then
    echo "Missing MAC for target: $target_name" >&2
    return 1
  fi

  if [ -z "$MM_PVE_HOST" ] || [ -z "$PVE_UBUNTU_JUMP_IP" ]; then
    echo "Missing jump host variables: MM_PVE_HOST/PVE_UBUNTU_JUMP_IP" >&2
    return 1
  fi

  ssh "$jump_target" "if command -v wakeonlan >/dev/null 2>&1; then wakeonlan -i '$broadcast_ip' -p '$port' '$target_mac'; elif command -v wol >/dev/null 2>&1; then wol -i '$broadcast_ip' '$target_mac'; else echo 'wakeonlan/wol not installed on jump host' >&2; exit 127; fi"
}
