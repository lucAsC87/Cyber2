ui_get_info(){
    clear
    echo -e "${BOLD}${COLOR_MENU}=== System Info ===${COLOR_RESET}\n"
    get_system_info
    read -p "Press [Enter] to return to System Info menu..."
}

ui_get_specs(){
    clear
    echo -e "${BOLD}${COLOR_MENU}=== HARDWARE INFO ===${COLOR_RESET}\n"
    get_hardware_info
    read -p "Press [Enter] to return to System Info menu..."
}