#!/bin/bash

# Main Menu options
main_menu=("Hardware Management" "Network Management" "User Management" "IPS" "EXIT")

# Submenus
hardware_menu=("CPU" "DISK" "RAM" "SYSTEM INFO" "BACK")
network_menu=("OPEN PORTS" "TRAFFIC" "LOGS" "BACK")
user_menu=("AUTHENTICATIONS" "INSTALLATIONS" "BACK")
ips_menu=("ONE TIME" "REAL TIME" "BACK")

# Sub-submenus for CPU and DISK
cpu_menu=("AVERAGE" "ALL" "BACK")
disk_menu=("AVERAGE" "ALL" "BACK")

# Arrow-key menu function (same as before)
navigate_menu() {
  local -n menu_items=$1
  local prompt="${2:-Select an option:}"
  local selected=0

  while true; do
    clear
    echo "=== $prompt ==="
    for i in "${!menu_items[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "> \e[1;32m${menu_items[$i]}\e[0m"
      else
        echo "  ${menu_items[$i]}"
      fi
    done

    # Read arrow key or enter
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 -t 0.1 key
    fi

    case "$key" in
      "[A")  # Up
        ((selected--))
        ((selected < 0)) && selected=$((${#menu_items[@]} - 1))
        ;;
      "[B")  # Down
        ((selected++))
        ((selected >= ${#menu_items[@]})) && selected=0
        ;;
      "")  # Enter
        return $selected
        ;;
    esac
  done
}

# Submenu dispatcher (updated to handle nested submenus)
handle_submenu() {
  local -n submenu=$1
  local title=$2

  while true; do
    navigate_menu submenu "$title"
    choice=$?

    # Handle sub-submenus:
    if [[ "$title" == "Hardware Management" ]]; then
      case "${submenu[$choice]}" in
        "CPU")
          handle_submenu cpu_menu "CPU"
          continue
          ;;
        "DISK")
          handle_submenu disk_menu "DISK"
          continue
          ;;
      esac
    fi

    if [[ "${submenu[$choice]}" == "BACK" ]]; then
      return
    fi

    clear
    echo ">>> ${submenu[$choice]} selected."
    read -p "Press Enter to return to $title..."
  done
}

# Main program loop
while true; do
  navigate_menu main_menu "Main Menu"
  choice=$?

  case $choice in
    0) handle_submenu hardware_menu "Hardware Management" ;;
    1) handle_submenu network_menu "Network Management" ;;
    2) handle_submenu user_menu "User Management" ;;
    3) handle_submenu ips_menu "IPS" ;;
    4) clear; echo "Exiting..."; exit ;;
  esac
done
