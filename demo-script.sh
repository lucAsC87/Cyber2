#!/bin/bash

export CYBER2_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source stat functions
source "$CYBER2_ROOT/resources/colors.sh"
source "$CYBER2_ROOT/scripts/system_monitoring_functions/cpu_stats.sh"
source "$CYBER2_ROOT/scripts/system_monitoring_functions/disk_stats.sh"
source "$CYBER2_ROOT/scripts/system_monitoring_functions/process_stats.sh"
source "$CYBER2_ROOT/scripts/system_monitoring_functions/system_info.sh"
source "$CYBER2_ROOT/scripts/system_monitoring_functions/memory_stats.sh"

# Menu definitions
main_menu=("Hardware Management" "Network Management" "User Management" "IPS" "EXIT")
hardware_menu=("SYSTEM INFO" "CPU" "DISK" "RAM" "back")
network_menu=("OPEN PORTS" "TRAFFIC" "LOGS" "back")
user_menu=("AUTH" "INSTALLATIONS" "back")
ips_menu=("ONE TIME" "REAL TIME" "back")
cpu_menu=("AVERAGE CPU UTIL" "ALL CPU UTIL" "back")
system_info_menu=("PROCESSES" "INFO" "SPECS" "back")

# Detect if menu entry is a submenu
is_menu() {
  case "$1" in
    "Hardware Management"|"Network Management"|"User Management"|"IPS"|"CPU"|"SYSTEM INFO")
      return 0
      ;;
    *) return 1 ;;
  esac
}

# Menu navigation handler
navigate_menu() {
  local -n menu_items=$1
  local prompt="${2:-Select an option:}"
  local selected=0

  while true; do
    clear
    echo -e "${BOLD}${BLUE}=== $prompt ===${RESET}"
    for i in "${!menu_items[@]}"; do
      local item="${menu_items[$i]}"
      local color

      if [[ "$item" == "back" || "$item" == "EXIT" ]]; then
        color=$COLOR_BACK
      elif is_menu "$item"; then
        color=$COLOR_MENU
      else
        color=$COLOR_ENDPOINT
      fi

      if [[ $i -eq $selected ]]; then
        echo -e "> ${COLOR_SELECTED}${item}${COLOR_RESET}"
      else
        echo -e "  ${color}${item}${COLOR_RESET}"
      fi
    done

    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 -t 0.1 key
    fi

    case "$key" in
      "[A") ((selected--)); ((selected < 0)) && selected=$((${#menu_items[@]} - 1)) ;;
      "[B") ((selected++)); ((selected >= ${#menu_items[@]})) && selected=0 ;;
      "") return $selected ;;
    esac
  done
}

# Submenu logic handler
handle_submenu() {
  local -n submenu=$1
  local title=$2

  while true; do
    navigate_menu submenu "$title"
    choice=$?
    selected="${submenu[$choice]}"

    # Handle back
    if [[ "$selected" == "back" ]]; then
      return
    fi

    case "$title" in
      "Hardware Management")
        case "$selected" in
          "CPU") handle_submenu cpu_menu "CPU" ;;
          "SYSTEM INFO") handle_submenu system_info_menu "SYSTEM INFO" ;;
          "DISK")
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            while true; do
              tput cup 0 0
              get_disk_io_stats
              echo -e "\nPress [Enter] to exit real-time view."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
          "RAM")
            clear
            tput civis  # Hide cursor
            trap "tput cnorm; stty echo" EXIT  # Restore cursor on exit
            while true; do
              tput cup 0 0
              get_memory_stats
              echo -e "\nPress [Enter] to exit RAM monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm  # Ensure cursor is shown again
            ;;
        esac
        ;;

      "CPU")
        case "$selected" in
          "AVERAGE CPU UTIL")
            clear
            tput civis  # Hide cursor
            trap "tput cnorm; stty echo" EXIT  # Restore cursor on exit
            while true; do
              tput cup 0 0
              get_average_cpu_stats
              echo -e "\nPress [Enter] to exit AVERAGE CPU monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
          "ALL CPU UTIL")
            clear
            tput civis  # Hide cursor
            trap "tput cnorm; stty echo" EXIT  # Restore cursor on exit
            while true; do
              tput cup 0 0
              get_all_cpu_stats
              echo -e "\nPress [Enter] to exit ALL CPU monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
        esac
        ;;

      "SYSTEM INFO")
        case "$selected" in
          "PROCESSES")
            clear
            show_process_tree
            read -p "Press Enter to return to SYSTEM INFO menu..."
            ;;
          "INFO")
            clear
            echo -e "${BOLD}${BLUE}=== SYSTEM INFO ===${RESET}"
            get_system_info
            read -p "Press Enter to return to SYSTEM INFO menu..."
            ;;
          "SPECS")
            clear
            echo -e "${BOLD}${BLUE}=== HARDWARE INFO ===${RESET}"
            get_hardware_info
            read -p "Press Enter to return to SYSTEM INFO menu..."
            ;;
        esac
        ;;

      "Network Management"|"User Management"|"IPS")
        clear
        echo -e "${COLOR_ENDPOINT}>>> '$selected' selected (feature not implemented yet).${COLOR_RESET}"
        read -p "Press Enter to return to $title menu..."
        ;;
    esac
  done
}

# Main program loop
while true; do
  navigate_menu main_menu "Main Menu"
  choice=$?
  selected="${main_menu[$choice]}"

  case "$selected" in
    "Hardware Management") handle_submenu hardware_menu "Hardware Management" ;;
    "Network Management") handle_submenu network_menu "Network Management" ;;
    "User Management") handle_submenu user_menu "User Management" ;;
    "IPS") handle_submenu ips_menu "IPS" ;;
    "EXIT") clear; echo "Exiting..."; exit 0 ;;
  esac
done
