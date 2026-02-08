pve-update() {
  local hosts=("pve" "pve2" "pbs")

  for host in "${hosts[@]}"; do
    case "$host" in
      pve)  target="$ADMIN_USER@$PVE_HOST" ;;
      pve2) target="$ADMIN_USER@$PVE2_HOST" ;;
      pbs)  target="$ADMIN_USER@$PBS_HOST" ;;
    esac

    echo "--- Updating $host ($target) ---"
    ssh -t "$target" "sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y"
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
