#!/usr/bin/env bash

# Get OS name
if command -v uname &> /dev/null; then
  os_name=$(uname -s)  # macOS or other Unix-like systems
fi

# Get OS version (for Linux systems)
if command -v lsb_release &> /dev/null; then
  # Should this re-assign os_name ?
  os_version=$(lsb_release -c | awk '{print $2}' 2>/dev/null)  # Linux
fi
