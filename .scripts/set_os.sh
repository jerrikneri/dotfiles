#!/bin/bash

# Determine the OS

if command -v uname &> /dev/null; then
  os_name=$(uname -s) # MacOS
fi

if command -v lsb_release &> /dev/null; then
  os_version=$(lsb_release -c | awk '{print $2}' 2>/dev/null) # Linux
fi


case "$os_name" in
Darwin)
  echo "Detected macOS"
  export CURRENT_OS=macOS
  ;;

Linux)
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
    arch | archarm)
      echo "Detected Arch Linux"
      export CURRENT_OS=arch
      ;;

    ubuntu | debian)
      echo "Detected Ubuntu/Debian"
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
