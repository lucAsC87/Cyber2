#!/bin/bash

# === Set Project Paths ===
# Determine the absolute path to this script's directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extract root project directory (assumes "Cyber2" is the project root folder).
PROJECT_DIR="$(echo "$SCRIPT_DIR" | sed -E 's|(.*\/Cyber2).*|\1|')"

# === Load Dependencies ===
# Source configuration and resource monitoring functions
source "$PROJECT_DIR/toolkit/config.sh"

# Create log directory if it doesn't exist and initialize the log file
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

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
              ui_get_info
              ;;
            "SPECS")
              ui_get_specs
              ;;
          esac
          ;;
      # === IDS Submenu ===
      "IDS")
        case "$selected" in
          "ONE TIME")
            ui_get_one_time
            ;;
          "REAL TIME")
            ui_get_real_time
            ;;
          esac
        ;;
      # === Hardware Submenu ===
      "Hardware Management")
        case "$selected" in
          "CPU") 
            ui_get_cpu
            ;;

          "DISK")
            ui_get_disk
            ;;

          "RAM")
            ui_get_ram
            ;;
        esac
        ;;

      # === Process Management Submenu ===
      "Process Management")
        case "$selected" in
          "DEMANDING PROCESSES")
            ui_get_demanding_process
            ;;
          "PROCESS TREE")
            ui_get_process_tree
            ;;
          "LOAD AVERAGE")
            ui_get_load_average
            ;;
        esac
        ;;

      # === Network Submenu ===
      "Network Management")
        case "$selected" in
          "TRAFFIC")
            ui_get_traffic
            ;;
          "CHECK SUPICIOUS PORT ACTIVITY")
            ui_get_supicious_port
            ;;
        esac
        ;;

      # === User Management Submenu ===
      "User Management")
        case "$selected" in
          "LOGS")
            ui_get_logs
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