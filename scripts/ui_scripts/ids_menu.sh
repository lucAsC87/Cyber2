ui_get_one_time(){
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
}

ui_get_real_time(){
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
}