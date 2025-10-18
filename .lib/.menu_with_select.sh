#!/usr/bin/env bash
# Base menu library — Bash + Zsh compatible

menu() {
  # $1 = associative array name (label → handler)
  local arr_name="$1"
  eval "local -A options=(\"\${${arr_name}[@]}\")" # get array values
  eval "local labels=(\"\${!${arr_name}[@]}\")"    # get keys

  echo $options
  echo
  echo $labels

  PS3="Enter option number: "

  while true; do
    echo
    select label in "${labels[@]}" "Quit"; do
      if [[ -z "$label" ]]; then
        echo "Invalid choice. Try again."
        continue 2
      fi

      [[ "$label" == "Quit" ]] && handle_quit

      # Call corresponding handler
      eval "handler=\"\${${arr_name}[\"$label\"]}\""
      echo "You selected: $label"
      $handler

      break
    done
  done
}

handle_quit() {
  echo "Exiting..."
  exit 0
}
