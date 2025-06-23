ui_get_traffic(){
    clear
    tput civis                  # Hide the cursor
    trap "tput cnorm; stty echo" EXIT  # Ensure cursor is restored when script exits
    
    echo -e "${BOLD}${COLOR_MENU}=== Network Traffic ===${COLOR_RESET}"
    
    IFACE=$(choose_interface)   # Prompt user to select a network interface
    
    while true; do
        output=$(show_traffic "$IFACE")  # Capture network traffic info for chosen interface
        
        tput cup 0 0; tput ed       # Reset cursor position and clear screen from cursor down
        
        echo -e "${BOLD}${COLOR_MENU}=== Network Traffic ===${COLOR_RESET}\n"
        echo "$output"
        
        echo -e "\nPress [Enter] to exit TRAFFIC monitoring."
        
        read -t 1 -s input && [[ -z "$input" ]] && break    # Exit if Enter pressed
    done
    
    tput cnorm                    # Restore cursor visibility
}

ui_get_supicious_port(){
    clear
    tput civis                   # Hide the cursor
    trap "tput cnorm; stty echo" EXIT  # Ensure cursor is restored when script exits
    
    echo -e "${BOLD}${COLOR_MENU}=== CHECKING SUPICIOUS PORT ACTIVITY ===${COLOR_RESET}"
    
    while true; do
        output=$(check_suspicious)   # Run check for suspicious port activity and capture output
        
        tput cup 0 0; tput ed       # Ensure cursor is restored when script exits
        
        echo -e "${BOLD}${COLOR_MENU}=== CHECKING SUPICIOUS PORT ACTIVITY ===${COLOR_RESET}"
        echo "$output"
        
        echo -e "\nPress [Enter] to exit  SUPICIOUS PORT ACTIVITY monitoring."
        
        read -t 1 -s input && [[ -z "$input" ]] && break    # Exit if Enter pressed
    done
    
    tput cnorm                   # Restore cursor visibility
}
