#!/bin/bash

# === Set Project Paths ===
# Determine the absolute path to this script's directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extract root project directory (assumes "Cyber2" is the project root folder).
PROJECT_DIR="$(echo "$SCRIPT_DIR" | sed -E 's|(.*\/Cyber2).*|\1|')"

# === Log File Setup ===
# Define log directory and file path
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/system_logs.log"

# Create log directory if it doesn't exist and initialize the log file
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# === Load Dependencies ===
# Source configuration and resource monitoring functions
source "$PROJECT_DIR/toolkit/config.sh"
source "$PROJECT_DIR/scripts/monitor-system-ressources.sh"
source "$PROJECT_DIR/scripts/monitor-network-traffic.sh"
source "$PROJECT_DIR/scripts/monitor-all.sh"


# === Menu Definitions ===
# Define main and submenu options as arrays
main_menu=("System Info" "IDS" "Hardware Management" "Process Management" "Network Management" "User Management" "EXIT")
hardware_menu=("CPU" "DISK" "RAM" "back")
network_menu=("TRAFFIC" "CHECK SUPICIOUS PORT ACTIVITY" "back")
user_menu=("LOGS" "back")
ids_menu=("ONE TIME" "REAL TIME" "back")
system_info_menu=("INFO" "SPECS" "back")
process_menu=("DEMANDING PROCESSES" "PROCESS TREE" "LOAD AVERAGE" "back")

# === Check if a menu item leads to a submenu ===
# Used to distinguish between actionable commands and navigable menus
is_menu() {
  case "$1" in
    "Hardware Management"|"Network Management"|"User Management"|"IDS"|"System Info"|"Process Management")
      return 0  # True: it's a submenu
      ;;
    *) return 1 ;;  # False: it's a final action
  esac
}

# === Menu Navigation Function ===
# Dynamically display and control any passed menu using keyboard input
navigate_menu() {
  local -n menu_items=$1         # Reference the array passed as the first argument
  local prompt=$2                # Prompt message to display
  local selected=0               # Currently highlighted item index

  while true; do
    clear
    echo -e "${BOLD}${COLOR_MENU}=== $prompt ===${COLOR_RESET}"

    # Render each menu item with appropriate coloring
    for i in "${!menu_items[@]}"; do
      local item="${menu_items[$i]}"
      local color

      # Assign a color based on item type: submenu, exit/back, or endpoint
      if [[ "$item" == "back" || "$item" == "EXIT" ]]; then
        color=$COLOR_BACK
      elif is_menu "$item"; then
        color=$COLOR_MENU
      else
        color=$COLOR_ENDPOINT
      fi

      # Highlight the currently selected menu item
      if [[ $i -eq $selected ]]; then
        echo -e "> ${COLOR_SELECTED}${item}${COLOR_RESET}"
      else
        echo -e "  ${color}${item}${COLOR_RESET}"
      fi
    done

    # === Handle Keyboard Navigation ===
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 -t 0.1 key  # Capture remaining bytes for arrow keys
    fi

    # Adjust selection based on arrow key or confirm with Enter
    case "$key" in
      "[A") ((selected--)); ((selected < 0)) && selected=$((${#menu_items[@]} - 1)) ;;  # Up arrow
      "[B") ((selected++)); ((selected >= ${#menu_items[@]})) && selected=0 ;;         # Down arrow
      "") return $selected ;;  # Enter pressed: return selected index
    esac
  done
}

# === Submenu Handling ===
# Recursively handle submenu navigation and invoke functionality
handle_submenu() {
  local -n submenu=$1
  local title=$2

  while true; do
    navigate_menu submenu "$title"
    choice=$?
    selected="${submenu[$choice]}"

    # Go back to the previous menu
    if [[ "$selected" == "back" ]]; then
      return
    fi

    case "$title" in
      # === System Info Submenu ===
        "System Info")
          case "$selected" in
            "INFO")
              clear
              echo -e "${BOLD}${COLOR_MENU}=== System Info ===${COLOR_RESET}\n"
              get_system_info
              read -p "Press [Enter] to return to System Info menu..."
              ;;
            "SPECS")
              clear
              echo -e "${BOLD}${COLOR_MENU}=== HARDWARE INFO ===${COLOR_RESET}\n"
              get_hardware_info
              read -p "Press [Enter] to return to System Info menu..."
              ;;
          esac
          ;;
      # === IDS Submenu ===
      "IDS")
        case "$selected" in
          "ONE TIME")
            LOG_FILE="$LOG_DIR/temp_logs.log"
            touch "$LOG_FILE"
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            echo -e "${BOLD}${COLOR_MENU}=== Choose Network Interface ===${COLOR_RESET}"
            IFACE=$(choose_interface)
            clear
            echo -e "${BOLD}${COLOR_MENU}=== Please Wait a Few Seconds to View the Warnings ===${COLOR_RESET}"
            monitor_all
            clear
            echo -e "${BOLD}${COLOR_MENU}=== WARNINGS!!!! ===${COLOR_RESET}"
            cat "$LOG_FILE"
            cat "$LOG_FILE" >> "$LOG_DIR/system_logs.log"
            WARNING_COUNT=$(wc -l < "$LOG_FILE")
            rm "$LOG_FILE"
            LOG_FILE="$LOG_DIR/system_logs.log"
            echo
            echo -e "Found $WARNING_COUNT warnings."
            read -p "Press [Enter] to return to IDS menu..."
            ;;
          "REAL TIME")
            clear
            echo -e "${BOLD}${COLOR_MENU}=== Choose Network Interface ===${COLOR_RESET}"
            IFACE=$(choose_interface)
            clear
            echo -e "${BOLD}${COLOR_MENU}=== Please Wait a Few Seconds to View the Warnings ===${COLOR_RESET}"
            WARNING_COUNT=0
            while true; do
              LOG_FILE="$LOG_DIR/temp_logs.log"
              touch $LOG_FILE
              monitor_all
              tput cup 0 0; tput ed
              echo -e "${BOLD}${COLOR_MENU}=== WARNINGS!!!! ===${COLOR_RESET}\n"
              cat $LOG_FILE
              cat $LOG_FILE >> "$LOG_DIR/system_logs.log"
              COUNT=$(wc -l < "$LOG_FILE")
              (( WARNING_COUNT += COUNT ))
              echo -e "\nFound $WARNING_COUNT warnings since the start of real time monitoring (view "$LOG_DIR/system_logs.log" to see them all)\nPress [Enter] to return to IDS menu..."
              rm $LOG_FILE
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            LOG_FILE="$LOG_DIR/system_logs.log"
            tput cnorm
            ;;
          esac
        ;;
      # === Hardware Submenu ===
      "Hardware Management")
        case "$selected" in
          "CPU") 
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            echo -e "${BOLD}${COLOR_MENU}=== Please Wait 2 Seconds for Real-Time CPU Utilization ===${COLOR_RESET}"
            while true; do
              avg_cpu=$(get_average_cpu_stats)
              all_cpu=$(get_all_cpu_stats)
              tput cup 0 0; tput ed
              echo -e "${BOLD}${COLOR_MENU}=== Real-Time CPU Average Utilization ===${COLOR_RESET}\n"
              echo "$avg_cpu"
              echo
              echo -e "${COLOR_MENU}${BOLD}=== Real-Time CPU Utilization Per Core ===${COLOR_RESET}\n"
              echo "$all_cpu"
              echo -e "\nPress [Enter] to exit AVERAGE CPU monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;

          "DISK")
            clear
            tput civis  # Hide cursor
            trap "tput cnorm; stty echo" EXIT  # Ensure cursor is restored on exit
            echo -e "${BOLD}${COLOR_MENU}=== Disk Usage and I/O ===${COLOR_RESET}"
            while true; do
              disk_usage=$(get_disk_usage)
              disk_io=$(get_disk_io_stats)
              tput cup 0 0; tput ed
              echo -e "${BOLD}${COLOR_MENU}=== Disk Usage ===${COLOR_RESET}\n"
              echo "$disk_usage"
              echo
              echo -e "\n${BOLD}${COLOR_MENU}=== Disk I/O Stats ===${COLOR_RESET}\n"
              echo "$disk_io"
              echo -e "\nPress [Enter] to exit real-time view."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;

          "RAM")
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            echo -e "${BOLD}${COLOR_MENU}=== Please Wait 1 Second for Real-Time Memory and Swap Usage ===${COLOR_RESET}"
            while true; do
              mem_stats=$(get_memory_stats)
              swap_stats=$(get_swap_stats)
              tput cup 0 0; tput ed
              echo -e "${BOLD}${COLOR_MENU}=== Real-Time Memory Usage ===${COLOR_RESET}\n"
              echo "$mem_stats"
              echo
              echo -e "\n${BOLD}${COLOR_MENU}=== Real-Time Swap Usage ===${COLOR_RESET}\n"
              echo "$swap_stats"
              echo -e "\nPress [Enter] to exit RAM monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
        esac
        ;;

      # === Process Management Submenu ===
      "Process Management")
        case "$selected" in
          "DEMANDING PROCESSES")
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            echo -e "${BOLD}${COLOR_MENU}=== Top CPU-consuming Processes ===${COLOR_RESET}"
            while true; do
              top_cpu_process=$(get_top_processes_cpu)
              top_mem_process=$(get_top_processes_mem)
              tput cup 0 0; tput ed
              echo -e "${BOLD}${COLOR_MENU}=== Top CPU-consuming Processes ===${COLOR_RESET}\n"
              echo "$top_cpu_process"
              echo
              echo -e "${BOLD}${COLOR_MENU}=== Top Memory-consuming Processes ===${COLOR_RESET}\n"
              echo "$top_mem_process"
              echo -e "\nPress [Enter] to exit DEMANDING PROCESS monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
          "PROCESS TREE")
            clear
            echo -e "${BOLD}${COLOR_MENU}=== Process Tree ===${COLOR_RESET}\n"
            show_process_tree
            read -p "Press [Enter] to return to Process Management menu..."
            ;;
          "LOAD AVERAGE")
            clear
            echo -e "${BOLD}${COLOR_MENU}=== Load Average Over 1min, 5min and 15min ===${COLOR_RESET}\n"
            show_load
            read -p "Press [Enter] to return to Process Management menu..."
            ;;
        esac
        ;;

      # === Network Submenu ===
      "Network Management")
        case "$selected" in
          "TRAFFIC")
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            echo -e "${BOLD}${COLOR_MENU}=== Network Traffic ===${COLOR_RESET}"
            IFACE=$(choose_interface)
            while true; do
              output=$(show_traffic "$IFACE")
              tput cup 0 0; tput ed
              echo -e "${BOLD}${COLOR_MENU}=== Network Traffic ===${COLOR_RESET}\n"
              echo "$output"
              echo -e "\nPress [Enter] to exit TRAFFIC monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
          "CHECK SUPICIOUS PORT ACTIVITY")
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            echo -e "${BOLD}${COLOR_MENU}=== CHECKING SUPICIOUS PORT ACTIVITY ===${COLOR_RESET}"
            while true; do
              output=$(check_suspicious)
              tput cup 0 0; tput ed
              echo -e "${BOLD}${COLOR_MENU}=== CHECKING SUPICIOUS PORT ACTIVITY ===${COLOR_RESET}"
              echo "$output"
              echo -e "\nPress [Enter] to exit  SUPICIOUS PORT ACTIVITY monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
        esac
        ;;

      # === User Management Submenu ===
      "User Management")
        case "$selected" in
          "LOGS")
            clear
            tput civis
            trap "tput cnorm; stty echo" EXIT
            while true; do
              harlod=$(source "$PROJECT_DIR/scripts/monitor-log-files.sh")
              tput cup 0 0; tput ed
              echo "$harlod"
              echo -e "\nPress [Enter] to exit LOGS monitoring."
              read -t 1 -s input && [[ -z "$input" ]] && break
            done
            tput cnorm
            ;;
        esac
        ;;
    esac
  done
}

# === Main Program Loop ===
# Show main menu and dispatch to submenus or exit
main() {
  while true; do
    navigate_menu main_menu "Main Menu"
    choice=$?
    selected="${main_menu[$choice]}"

    case "$selected" in
      "Hardware Management") handle_submenu hardware_menu "Hardware Management" ;;
      "Network Management") handle_submenu network_menu "Network Management" ;;
      "User Management") handle_submenu user_menu "User Management" ;;
      "IDS") handle_submenu ids_menu "IDS" ;;
      "System Info") handle_submenu system_info_menu "System Info" ;;
      "Process Management") handle_submenu process_menu "Process Management" ;;
      "EXIT") 
        clear
        echo "Exiting..."
        exit 0 ;;
    esac
  done
}

# Start the application
main