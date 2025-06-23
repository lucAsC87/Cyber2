ui_get_traffic(){
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
}

ui_get_supicious_port(){
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
}