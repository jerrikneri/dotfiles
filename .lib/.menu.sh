#!/usr/bin/env zsh
# Zsh-compatible reusable menu library

handle_quit() {
  echo "Exiting..."
  exit 0
}

menu() {
  local arr_name=$1        # name of associative array
  typeset -n menu_items=$arr_name  # nameref to associative array
  local keys=("${(@k)menu_items}") # keys of the array

  if (( ${#keys[@]} == 0 )); then
    echo "No menu items provided."
    return 1
  fi

  while true; do
    clear
    echo -e "\t\t\tMenu\n"

    local i=1
    for key in "${keys[@]}"; do
      echo -e "\t$i. $key"
      ((i++))
    done
    echo -e "\tq. Quit"

    echo -en "\n\tEnter Option (number, 'q', or ESC): "
    read -rk1 option
    echo

    # Quit on q/Q/ESC
    [[ "$option" == "q" || "$option" == "Q" || "$option" == $'\e' ]] && handle_quit

    # Validate numeric input
    if [[ ! "$option" =~ ^[0-9]+$ ]] || (( option < 1 || option > ${#keys[@]} )); then
      echo "Invalid choice. Try again."
      sleep 1
      continue
    fi

    local choice="${keys[$((option-1))]}"
    local handler="${menu_items[$choice]}"

    echo -e "\nYou selected: $choice\n"

    # Call the handler function
    if whence -w "$handler" >/dev/null 2>&1; then
      "$handler"
    else
      echo "Handler '$handler' not found."
    fi

    echo -e "\nPress any key to return to menu..."
    read -rk1
  done
}

