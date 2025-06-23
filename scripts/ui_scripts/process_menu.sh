ui_get_demanding_process(){
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
}

ui_get_process_tree(){
    clear
    echo -e "${BOLD}${COLOR_MENU}=== Process Tree ===${COLOR_RESET}\n"
    show_process_tree
    read -p "Press [Enter] to return to Process Management menu..."
}

ui_get_load_average(){
    clear
    echo -e "${BOLD}${COLOR_MENU}=== Load Average Over 1min, 5min and 15min ===${COLOR_RESET}\n"
    show_load
    read -p "Press [Enter] to return to Process Management menu..."
}