show_process_tree() {
    if command -v pstree &>/dev/null; then
        pstree -lAC age
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

# Function to get top processes
get_top_processes_cpu() {
    process_tree_cpu=""
    while IFS= read -r line; do
        read -r user pid cpu path <<<"$line"
        process_tree_cpu+="$(print_metric "${user} (%)" "$cpu" $DEFAULT_PROCESS_CPU_THRESHOLD "over" "Process ${pid} is using a lot of compute power")  PID: $pid  $path\n"
    done < <(ps aux --sort=-%cpu | grep -v "[p]s aux" | head -21 | tail -20 | awk '{
        cmd=""; 
        for(i=11;i<=NF;i++) cmd=cmd $i (i==NF ? "" : " ");
        printf "%s %s %s %s\n", $1, $2, $3, $11
    }')
    echo -e "$process_tree_cpu"

}

get_top_processes_mem(){
    process_tree_mem=""
    while IFS= read -r line; do
        read -r user pid mem path <<<"$line"
        process_tree_mem+="$(print_metric "${user} (%)" "$mem" $DEFAULT_PROCESS_MEM_THRESHOLD "over" "Process ${pid} is using a lot of memory")  PID: $pid  $path\n"
    done < <(ps aux --sort=-%mem | grep -v "[p]s aux" | head -21 | tail -20 | awk '{
        cmd="";
        for(i=11;i<=NF;i++) cmd=cmd $i (i==NF ? "" : " ");
        printf "%s %s %s %s\n", $1, $2, $4, $11
    }')
    echo -e "$process_tree_mem"
}