#!/usr/bin/env bash

source $SCRIPTS/utils.sh
source $SCRIPTS/get_os_variables.sh

case "$os_name" in
Darwin)
  _debug_echo "Current OS is macOS"
  export CURRENT_OS=macOS
  ;;

Linux)
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
    arch | archarm)
      _debug_echo "Current OS is Arch Linux"
      export CURRENT_OS=arch
      ;;

    nixos)
      _debug_echo "Current OS is NixOS"
      export CURRENT_OS=nixos
      ;;

    ubuntu | debian)
      _debug_echo "Current OS is Ubuntu/Debian"
      export CURRENT_OS=debian
      ;;

    *)
      _debug_echo "Unsupported Linux distribution: $ID"
      ;;
    esac
  else
    _debug_echo "Unsupported Linux distribution"
  fi
  ;;

*)
  _debug_echo "Unsupported OS: $os_name"
  ;;
esac
