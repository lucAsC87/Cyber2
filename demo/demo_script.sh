#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(echo "$SCRIPT_DIR" | sed -E 's|(.*\/Cyber2).*|\1|')"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/system_logs.log"
# Source stat functions
source "$PROJECT_DIR/toolkit/config.sh"
source "$PROJECT_DIR/scripts/monitor-system-ressources.sh"

mkdir -p "$LOG_DIR"
touch $LOG_FILE

# Menu definitions
main_menu=("System Info" "Hardware Management" "Process Management" "Network Management" "User Management" "IPS" "EXIT")
hardware_menu=("CPU" "DISK" "RAM" "back")
network_menu=("PORTS" "TRAFFIC" "back")
user_menu=("AUTH" "INSTALLATIONS" "back")
ips_menu=("ONE TIME" "REAL TIME" "back")
cpu_menu=("AVERAGE CPU UTIL" "ALL CPU UTIL" "back")
system_info_menu=("INFO" "SPECS" "back")
process_menu=("DEMANDING PROCESSES" "PROCESS TREE" "LOAD AVERAGE" "back")

# Detect if menu entry is a submenu
is_menu() {
  case "$1" in
    "Hardware Management"|"Network Management"|"User Management"|"IPS"|"CPU"|"System Info"|"Process Management")
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
    echo -e "${BOLD}${COLOR_MENU}=== $prompt ===${COLOR_RESET}"
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
          "DISK")
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            echo -e "${BOLD}${COLOR_MENU}=== Disk Usage ===${COLOR_RESET}"
            while true; do
              disk_usage=$(get_disk_usage)
              disk_io=$(get_disk_io_stats)
              tput cup 0 0
              tput ed
              echo -e "${BOLD}${COLOR_MENU}=== Disk Usage ===${COLOR_RESET}"
              echo "$disk_usage"
              echo -e "\n${BOLD}${COLOR_MENU}=== Disk I/O Stats ===${COLOR_RESET}"
              echo "$disk_io"
              echo -e "\nPress [Enter] to exit real-time view."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
          "RAM")
            clear
            tput civis  # Hide cursor
            trap "tput cnorm; stty echo" EXIT  # Restore cursor on exit
            echo -e "${BOLD}${COLOR_MENU}=== Real-Time Memory Usage ===${COLOR_RESET}"
            while true; do
              memory_stats=$(get_memory_stats)
              swap_stats=$(get_swap_stats)
              tput cup 0 0
              tput ed
              echo -e "${BOLD}${COLOR_MENU}=== Real-Time Memory Usage ===${COLOR_RESET}"
              echo "$memory_stats"
              echo -e "\n${BOLD}${COLOR_MENU}=== Real-Time Swap Usage ===${COLOR_RESET}"
              echo "$swap_stats"
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
            echo -e "${BOLD}${COLOR_MENU}=== Real-Time CPU Average Utilization ===${COLOR_RESET}"
            while true; do
              average_cpu=$(get_average_cpu_stats)  # Capture output instead of printing it live
              tput cup 0 0
              tput ed
              echo -e "${BOLD}${COLOR_MENU}=== Real-Time CPU Average Utilization ===${COLOR_RESET}"
              echo "$average_cpu"
              echo -e "\nPress [Enter] to exit AVERAGE CPU monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
          "ALL CPU UTIL")
            clear
            tput civis  # Hide cursor
            trap "tput cnorm; stty echo" EXIT  # Restore cursor on exit
            echo -e "${COLOR_MENU}${BOLD}=== Real-Time CPU Utilization Per Core ===${COLOR_RESET}"
            while true; do
              all_cpu=$(get_all_cpu_stats)
              tput cup 0 0
              tput ed
              echo -e "${COLOR_MENU}${BOLD}=== Real-Time CPU Utilization Per Core ===${COLOR_RESET}"
              echo "$all_cpu"
              echo -e "\nPress [Enter] to exit ALL CPU monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done  
            tput cnorm
            ;;
        esac
        ;;

      "System Info")
        case "$selected" in
          "INFO")
            clear
            echo -e "${BOLD}${COLOR_MENU}=== System Info ===${COLOR_RESET}"
            get_system_info
            read -p "Press Enter to return to System Info menu..."
            ;;
          "SPECS")
            clear
            echo -e "${BOLD}${COLOR_MENU}=== HARDWARE INFO ===${COLOR_RESET}"
            get_hardware_info
            read -p "Press Enter to return to System Info menu..."
            ;;
        esac
        ;;
      "Network Management")
        case "$selected" in
          "TRAFFIC")
            clear
            source "$PROJECT_DIR/scripts/monitor-network-traffic.sh"
            read -p "Press Enter to return to System Info menu..."
            ;;
          "PORTS")
            clear
            echo -e "${BOLD}${COLOR_MENU}=== System Info ===${COLOR_RESET}"
            get_system_info
            read -p "Press Enter to return to System Info menu..."
            ;;
        esac
        ;;
      "Process Management")
        case "$selected" in
          "DEMANDING PROCESSES")
            clear
            tput civis  # Hide cursor
            trap "tput cnorm; stty echo" EXIT  # Restore cursor on exit
            while true; do
              demanding_processes=$(get_top_processes)
              tput cup 0 0
              tput ed
              echo "$demanding_processes"
              echo -e "\nPress [Enter] to exit DEMANDING PROCESS monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done  
            tput cnorm
            ;;
          "PROCESS TREE")
            clear
            echo -e "${BOLD}${COLOR_MENU}=== Process Tree ===${COLOR_RESET}"
            show_process_tree
            read -p "Press Enter to return to Process Management menu..."
            ;;
          "LOAD AVERAGE")
            clear
            echo -e "${BOLD}${COLOR_MENU}=== Load Average ===${COLOR_RESET}"
            show_load
            read -p "Press Enter to return to Process Management menu..."
            ;;
        esac
        ;;
      "User Management"|"IPS")
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
    "System Info") handle_submenu system_info_menu "System Info" ;;
    "Process Management") handle_submenu process_menu "Process Management" ;;
    "EXIT") clear; echo "Exiting..."; exit 0 ;;
  esac
done