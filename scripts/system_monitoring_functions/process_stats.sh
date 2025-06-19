show_process_tree() {
    echo -e "${COLOR_MENU}${BOLD}=== Top 10 Processes by Memory Usage ===${COLOR_RESET}"
    echo "PID: Process ID, PPID: Parent Process ID, CMD: Command name, %MEM: Memory usage percentage, %CPU: CPU usage percentage"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 11
    echo -e "\n${COLOR_MENU}${BOLD}=== Process Tree (first 20 lines) ===${COLOR_RESET}"
    echo "Shows process hierarchy with PIDs."
    if command -v pstree &>/dev/null; then
        pstree -p --show-pids | head -n 20
    else
        echo "pstree not found. Please install the psmisc package."
    fi
    echo
}

show_load() {

    echo "Load average indicates the average number of processes waiting to run."
    echo "Values correspond to 1 minute, 5 minutes, and 15 minutes intervals respectively."
    echo "Lower values mean the system is less busy; values higher than your CPU count indicate possible overload."
    load_vals=$(uptime | awk -F 'load average:' '{ print $2 }' | sed 's/^ *//')
    # Split into 3 variables
    IFS=', ' read -r load1 load5 load15 <<< "$load_vals"
    echo "1 minute:  $load1"
    echo "5 minutes: $load5"
    echo "15 minutes:$load15"
    echo
}