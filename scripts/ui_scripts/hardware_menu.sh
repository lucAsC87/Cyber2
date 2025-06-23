ui_get_cpu(){
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
}

ui_get_disk(){
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
}

ui_get_ram(){
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
}