#!/usr/bin/env zsh

# Debug echo - only outputs in interactive shells when SHELL_DEBUG=true
_debug_echo() {
  [[ -o interactive && "$SHELL_DEBUG" == "true" ]] && echo "$@"
}
