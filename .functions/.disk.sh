flashboot() {
  local iso_path="${1:-}"

  if [ -z "$iso_path" ]; then
    echo "Usage: flashboot <path-to-iso>" >&2
    echo "" >&2
    echo "List USB drives and write an ISO/image with dd." >&2
    echo "Works on macOS and Linux." >&2
    return 1
  fi

  if [ ! -f "$iso_path" ]; then
    echo "Error: not a file: $iso_path" >&2
    return 1
  fi

  local iso_size device confirm dd_rc=0
  iso_size=$(du -h "$iso_path" | cut -f1)

  echo "Image: $iso_path ($iso_size)"
  echo ""

  case "$OSTYPE" in
    darwin*)
      echo "Connected USB drives:"
      echo "---"
      diskutil list external physical 2>/dev/null || {
        echo "  No external drives found." >&2
        return 1
      }
      echo "---"
      ;;
    linux*)
      echo "Connected drives:"
      echo "---"
      lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL 2>/dev/null || {
        echo "  lsblk not available." >&2
        return 1
      }
      echo "---"
      ;;
    *)
      echo "Error: unsupported OS ($OSTYPE)" >&2
      return 1
      ;;
  esac

  echo ""
  printf "Enter target device (e.g. /dev/disk4 or /dev/sdb): "
  read -r device

  if [ -z "$device" ]; then
    echo "Aborted." >&2
    return 1
  fi

  if [ ! -e "$device" ]; then
    echo "Error: device not found: $device" >&2
    return 1
  fi

  echo ""
  echo "WARNING: This will DESTROY all data on $device"
  echo "Image:  $iso_path ($iso_size)"
  echo "Target: $device"
  echo ""
  printf "Type 'yes' to confirm: "
  read -r confirm

  if [ "$confirm" != "yes" ]; then
    echo "Aborted." >&2
    return 1
  fi

  echo ""

  if [[ "$OSTYPE" == darwin* ]]; then
    local raw_device="${device/disk/rdisk}"
    echo "Unmounting $device ..."
    diskutil unmountDisk "$device" 2>/dev/null || {
      echo "Error: failed to unmount $device" >&2
      return 1
    }
    echo "Writing to $raw_device ..."
    if command -v pv >/dev/null 2>&1; then
      pv "$iso_path" | sudo dd of="$raw_device" bs=4M
    else
      sudo dd if="$iso_path" of="$raw_device" bs=4M
    fi
    dd_rc=$?
    echo "Syncing ..."
    sync
  else
    echo "Writing to $device ..."
    if command -v pv >/dev/null 2>&1; then
      pv "$iso_path" | sudo dd of="$device" bs=4M
      sync
    else
      sudo dd if="$iso_path" of="$device" bs=4M status=progress conv=fsync
    fi
    dd_rc=$?
  fi

  if [ "$dd_rc" -ne 0 ]; then
    echo "" >&2
    echo "dd exited with code $dd_rc" >&2
    return "$dd_rc"
  fi

  echo ""
  echo "Done. You can now boot from the USB drive."

  if [[ "$OSTYPE" == darwin* ]]; then
    diskutil eject "$device" 2>/dev/null
  fi
}
