#!/usr/bin/env bash
# Fix for: error: Path "/var/tmp" is world-writable or a symlink
# Cause: stale build-dir = /var/tmp/nix-builds in /etc/nix/nix.conf
# The NixOS config (nix-settings.nix) already removed build-dir,
# but the old config blocks rebuilding. This overrides for one rebuild.
# Usage: ./fix-build-dir.sh [hostname]
#   Without args: auto-detects hostname from 'hostname' command
#   With arg:     ./fix-build-dir.sh nixos-game
set -euo pipefail

HOSTNAME="${1:-$(hostname)}"
echo "=== Fixing build-dir for host: $HOSTNAME ==="
echo "=== Creating /var/cache/nix (non-world-writable build dir) ==="
sudo mkdir -p /var/cache/nix && sudo chmod 755 /var/cache/nix
echo "=== Rebuilding with build-dir override ==="
sudo nixos-rebuild switch --flake "~/code/dotfiles/nix#$HOSTNAME" --option build-dir /var/cache/nix
echo "=== Done. build-dir override removed from /etc/nix/nix.conf. Future builds will use default /tmp. ==="
