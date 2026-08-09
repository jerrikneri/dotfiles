#!/usr/bin/env bash

set -euo pipefail

# Usage: sync-cryptomator-vaults.sh
#        sync-cryptomator-vaults.sh <dest_vault>
#        sync-cryptomator-vaults.sh <src_vault> <dest_vault>
#
# Syncs encrypted Cryptomator vaults via rsync.
# Both source and destination vaults MUST be locked first.
#
# Reads CRYPTOMATOR_VAULT_SRC and CRYPTOMATOR_CHANGELOG from env (set in $DOTFILES/.env)
# No args: detects connected external drives, picks one, constructs dest path
#          from the source vault's basename (e.g. "main" → /Volumes/USB/main)
# One arg:  uses source vault from env, dest is the explicit arg
# Two args: overrides both source and destination

validate_vault() {
  local path="$1" label="$2"
  [[ -d "$path" ]] || { echo "Error: $label not found: $path" >&2; exit 1; }
  [[ -f "$path/masterkey.cryptomator" ]] || {
    echo "Error: $label appears unlocked or is not a Cryptomator vault: $path" >&2
    exit 1
  }
}

append_changelog() {
  local changelog="$1" src="$2" dest="$3"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  mkdir -p "$(dirname "$changelog")"

  if [[ ! -f "$changelog" ]]; then
    {
      echo "# Vault Sync Changelog"
      echo ""
    } > "$changelog"
  fi

  {
    echo "### $timestamp"
    echo "- **Action:** Synced encrypted vault via sync-cryptomator-vaults.sh"
    echo "- **Source:** \`$src\`"
    echo "- **Destination:** \`$dest\`"
    echo ""
  } >> "$changelog"
}

detect_drives() {
  local volumes=()
  local labels=()
  local device mountpoint

  echo "Scanning /Volumes for external drives..."

  for mountpoint in /Volumes/*; do
    [[ -e "$mountpoint" ]] || continue
    local volname; volname="$(basename "$mountpoint")"

    if [[ -L "$mountpoint" ]]; then
      echo "  SKIP $volname — symlink (not a real mount)" >&2
      continue
    fi
    if [[ ! -d "$mountpoint" ]]; then
      echo "  SKIP $volname — not a directory" >&2
      continue
    fi

    local fs_type
    fs_type=$(mount | grep -F "on $mountpoint (" | head -1 | sed 's/.*(\([^,]*\).*/\1/')
    if [[ "$fs_type" =~ ^(smbfs|afpfs|nfs|cifs)$ ]]; then
      echo "  KEEP $volname — network share ($fs_type)"
      labels+=("$volname")
      volumes+=("$mountpoint")
      continue
    fi

    local info
    info=$(diskutil info "$mountpoint" 2>/dev/null) || {
      echo "  SKIP $volname — diskutil failed" >&2
      continue
    }
    device=$(echo "$info" | awk '/Device Node:/ {print $NF}')
    if [[ -z "$device" ]]; then
      echo "  SKIP $volname — no device node found" >&2
      continue
    fi

    local base_disk
    base_disk="${device%s[0-9]*}"

    if ! diskutil list external | grep -qF "$base_disk"; then
      local fs_type
      fs_type=$(mount | grep -F "on $mountpoint (" | head -1 | sed 's/.*(\([^,]*\).*/\1/')
      if [[ "$fs_type" =~ ^(smbfs|afpfs|nfs|cifs)$ ]]; then
        echo "  KEEP $volname — network share ($fs_type)"
        labels+=("$volname")
        volumes+=("$mountpoint")
        continue
      fi
      echo "  SKIP $volname ($device) — not an external or network drive" >&2
      continue
    fi

    echo "  KEEP $volname ($device) — external drive"
    labels+=("$volname")
    volumes+=("$mountpoint")
  done

  if [[ ${#volumes[@]} -eq 0 ]]; then
    echo ""
    echo "No external drives detected. Plug one in and try again." >&2
    echo "If a drive is plugged in but not listed above, check:" >&2
    echo "  diskutil list external" >&2
    echo "  ls -la /Volumes/" >&2
    exit 1
  fi

  echo ""
  echo "Available external drives:"
  local i
  for i in "${!volumes[@]}"; do
    printf "  %d) %s\n" $((i + 1)) "${labels[$i]}"
  done

  local choice
  printf "Select drive [1-%d]: " "${#volumes[@]}"
  read -r choice

  [[ "$choice" =~ ^[0-9]+$ ]] || { echo "Invalid selection." >&2; exit 1; }
  [[ "$choice" -ge 1 && "$choice" -le "${#volumes[@]}" ]] || { echo "Invalid selection." >&2; exit 1; }

  SELECTED_DRIVE="${volumes[$((choice - 1))]}"
}

sync_flow() {
  local src="$1" dest="$2"
  local backup_dir
  backup_dir="$(dirname "$dest")/_backups/$(basename "$dest")/$(date +%Y%m%d_%H%M%S)"

  validate_vault "$src"  "Source vault"
  validate_vault "$dest" "Destination vault"

  mkdir -p "$backup_dir"

  echo "Backup dir: $backup_dir"
  echo ""
  echo "Syncing (dry-run): $src → $dest"
  rsync -av --delete --backup --backup-dir="$backup_dir" --dry-run "$src/" "$dest/"

  read -r -p "Apply these changes? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi

  rsync -av --delete --backup --backup-dir="$backup_dir" "$src/" "$dest/" && {
    echo "Synced: $src → $dest"
    local backed_up; backed_up=$(find "$backup_dir" -type f -not -path '*/.*' | wc -l | tr -d ' ')
    if [[ "$backed_up" -gt 0 ]]; then
      echo "Backed up $backed_up changed/deleted files to: $backup_dir"
    else
      echo "No files changed — backup dir is empty."
    fi
  }
  echo "Logged to: $CHANGELOG"
}

# --- Main ---
SRC="${CRYPTOMATOR_VAULT_SRC:-}"
CHANGELOG="${CRYPTOMATOR_CHANGELOG:-}"
[[ -n "$CHANGELOG" ]] || { echo "Error: CRYPTOMATOR_CHANGELOG not set in environment" >&2; exit 1; }

case "$#" in
  0)
    [[ -n "$SRC" ]] || { echo "Error: CRYPTOMATOR_VAULT_SRC not set in environment" >&2; exit 1; }
    detect_drives
    VAULT_NAME="$(basename "$SRC")"
    DEST="$SELECTED_DRIVE/$VAULT_NAME"
    echo "Vault: $VAULT_NAME"
    echo "Drive: $SELECTED_DRIVE"
    echo ""

    if [[ ! -d "$DEST" ]]; then
      echo "Vault '$VAULT_NAME' not found on '$SELECTED_DRIVE'."
      read -r -p "Create and clone from source? [y/N] " create
      if [[ "$create" =~ ^[Yy]$ ]]; then
        echo "To create a new vault clone on this drive:"
        echo "  1. Open Cryptomator, add existing vault: $DEST"
        echo "  2. Unlock it once, then lock it again"
        echo "  3. Re-run this script to sync"
        echo ""
        echo "Or manually copy the locked vault directory:"
        echo "  rsync -av $SRC/ $DEST/"
        exit 0
      fi
      exit 0
    fi
    ;;
  1)
    [[ -n "$SRC" ]] || { echo "Error: CRYPTOMATOR_VAULT_SRC not set in environment and no source arg provided" >&2; exit 1; }
    DEST="$1"
    ;;
  2)
    SRC="$1"
    DEST="$2"
    ;;
  *)
    echo "Usage: $0"
    echo "       $0 <dest_vault>"
    echo "       $0 <src_vault> <dest_vault>"
    echo ""
    echo "  Both vaults must be LOCKED."
    echo "  No args: auto-detect external drives, prompt to pick one"
    echo ""
    echo "  Required env vars (set in \$DOTFILES/.env):"
    echo "    CRYPTOMATOR_VAULT_SRC  — path to locked source vault"
    echo "    CRYPTOMATOR_CHANGELOG  — path to changelog file"
    echo ""
    echo "Examples:"
    echo "  $0                              # detect drives, pick one"
    echo "  $0 /Volumes/USB-Backup/my-vault # explicit dest"
    exit 1
    ;;
esac

sync_flow "$SRC" "$DEST"
append_changelog "$CHANGELOG" "$SRC" "$DEST"
