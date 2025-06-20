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

ascii="                                   
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
@@                                   @@
@@  @  @  @                          @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@                                   @@
@@                                   @@
@@                                   @@
@@         @@             @@         @@
@@        @@@@           @@@@        @@
@@        @@@@     @@@   @@@@@       @@
@@       @@ @@    @@@@  @@  @@       @@
@@@@@@@@@@   @@   @@ @@ @@   @@@@@@@@@@
@@           @@  @@  @@@@            @@
@@            @ @@    @@@            @@
@@            @@@@     @             @@
@@            @@@                    @@
@@             @                     @@
@@                                   @@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "

# Menu definitions
main_menu=("System Info" "Hardware Management" "Network Management" "User Management" "IPS" "EXIT")
hardware_menu=("CPU" "DISK" "RAM" "back")
network_menu=("OPEN PORTS" "TRAFFIC" "LOGS" "back")
user_menu=("AUTH" "INSTALLATIONS" "back")
ips_menu=("ONE TIME" "REAL TIME" "back")
cpu_menu=("AVERAGE CPU UTIL" "ALL CPU UTIL" "back")
system_info_menu=("PROCESSES" "INFO" "SPECS" "back")

# Get ASCII art for menu
get_menu_ascii() {
    case "$1" in
        "main_menu") echo "$ascii" ;;
        "hardware_menu") echo "$hardware_ascii" ;;
        "network_menu") echo "$network_ascii" ;;
        "user_menu") echo "$user_ascii" ;;
        "ips_menu") echo "$ips_ascii" ;;
        "cpu_menu") echo "$cpu_ascii" ;;
        "system_info_menu") echo "$system_info_ascii" ;;
        *) echo "$ascii" ;;
    esac
}

# Get menu title
get_menu_title() {
    case "$1" in
        "main_menu") echo "SYSTEM MONITORING DASHBOARD" ;;
        "hardware_menu") echo "HARDWARE MANAGEMENT" ;;
        "network_menu") echo "NETWORK MANAGEMENT" ;;
        "user_menu") echo "USER MANAGEMENT" ;;
        "ips_menu") echo "INTRUSION PREVENTION SYSTEM" ;;
        "cpu_menu") echo "CPU MONITORING" ;;
        "system_info_menu") echo "SYSTEM INFORMATION" ;;
        *) echo "MENU" ;;
    esac
}

# Detect if menu entry is a submenu
is_menu() {
  case "$1" in
    "Hardware Management"|"Network Management"|"User Management"|"IPS"|"CPU"|"System Info")
      return 0
      ;;
    *) return 1 ;;
  esac
}

# Unified menu display for all menus
display_menu() {
    local -n menu_items=$1
    local selected=$2
    local menu_name=$1
    local title=$(get_menu_title "$menu_name")
    local menu_ascii=$(get_menu_ascii "$menu_name")
    
    clear
    
    # Split ASCII into lines for side-by-side display
    mapfile -t ascii_lines <<< "$ascii"
    
    # Header
    echo -e "${BOLD}${COLOR_MENU}╔══════════════════════════════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${BOLD}${COLOR_MENU}║$(printf "%*s" $(((78-${#title})/2)) "")${title}$(printf "%*s" $(((78-${#title})/2)) "")║${COLOR_RESET}"
    echo -e "${BOLD}${COLOR_MENU}╚══════════════════════════════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""

    
    # Calculate where to start menu items (adjust based on ASCII height)
    local max_lines=${#ascii_lines[@]}
    local menu_start_line
    
    menu_start_line=1
    
    # Display ASCII art and menu side by side
    for ((i=0; i<max_lines; i++)); do
        # Print ASCII line (left side) - pad to 40 characters
        printf "%-40s" "${ascii_lines[$i]}"
        
        # Print menu item (right side)
        if [[ $((i-menu_start_line)) -ge 0 && $((i-menu_start_line)) -lt ${#menu_items[@]} ]]; then
            local menu_index=$((i-menu_start_line))
            local item="${menu_items[$menu_index]}"
            local color
            
            if [[ "$item" == "EXIT" || "$item" == "back" ]]; then
                color=$COLOR_BACK
            elif is_menu "$item"; then
                color=$COLOR_MENU
            else
                color=$COLOR_ENDPOINT
            fi
            
            if [[ $menu_index -eq $selected ]]; then
                echo -e "    > ${COLOR_SELECTED}${item}${COLOR_RESET}"
            else
                echo -e "      ${color}${item}${COLOR_RESET}"
            fi
        else
            echo ""
        fi
    done
    
    echo ""
    echo -e "${BOLD}${COLOR_MENU}═══════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    
    # Show real-time stats only for main menu
    if [[ "$menu_name" == "main_menu" ]]; then
        echo -e "${BOLD}${COLOR_ENDPOINT}Real-time Stats: $(get_realtime_stats)${COLOR_RESET}"
        echo -e "${BOLD}${COLOR_MENU}═══════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
        echo ""
        get_top_processes
        echo ""
    else
        echo -e "${BOLD}${COLOR_ENDPOINT}Navigate: ↑/↓ arrows │ Select: Enter │ Back: Select 'back'${COLOR_RESET}"
        echo -e "${BOLD}${COLOR_MENU}═══════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
        echo ""
    fi
    
    echo -e "${BOLD}${COLOR_MENU}Use ↑/↓ arrows to navigate, Enter to select${COLOR_RESET}"
}

# Unified menu navigation for all menus
navigate_menu() {
    local -n menu_items=$1
    local menu_name=$1
    local selected=0
    
    while true; do
        display_menu "$1" $selected
        
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
  local submenu_name=$1
  while true; do
    navigate_menu submenu
    choice=$?
    selected="${submenu[$choice]}"

    # Handle back
    if [[ "$selected" == "back" ]]; then
      return
    fi

    case "$submenu_name" in
      "hardware_menu")
        case "$selected" in
          "CPU") handle_submenu cpu_menu ;;
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

      "cpu_menu")
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

      "system_info_menu")
        case "$selected" in
          "PROCESSES")
            clear
            show_process_tree
            read -p "Press Enter to return to System Info menu..."
            ;;
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

      "network_menu"|"user_menu"|"ips_menu")
        clear
        echo -e "${COLOR_ENDPOINT}>>> '$selected' selected (feature not implemented yet).${COLOR_RESET}"
        read -p "Press Enter to return to menu..."
        ;;
    esac
  done
}

# Main program loop
while true; do
  navigate_menu main_menu
  choice=$?
  selected="${main_menu[$choice]}"

  case "$selected" in
    "Hardware Management") handle_submenu hardware_menu ;;
    "Network Management") handle_submenu network_menu ;;
    "User Management") handle_submenu user_menu ;;
    "IPS") handle_submenu ips_menu ;;
    "System Info") handle_submenu system_info_menu ;;
    "EXIT") clear; echo "Exiting..."; exit 0 ;;
  esac
done