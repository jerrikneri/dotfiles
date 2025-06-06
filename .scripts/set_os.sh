#!/bin/bash

source $SCRIPTS/get_os_variables.sh

case "$os_name" in
Darwin)
  echo "Current OS is macOS"
  export CURRENT_OS=macOS
  ;;

Linux)
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
    arch | archarm)
      echo "Current OS is Arch Linux"
      export CURRENT_OS=arch
      ;;

    nixos)
      echo "Current OS is NixOS"
      export CURRENT_OS=nixos
      ;;

    ubuntu | debian)
      echo "Current OS is Ubuntu/Debian"
      export CURRENT_OS=debian
      ;;

    *)
      echo "Unsupported Linux distribution: $ID"
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
