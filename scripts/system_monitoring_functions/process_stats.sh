show_process_tree() {
    if command -v pstree &>/dev/null; then
        pstree -lAC age
    else
        echo "pstree not found. Please install the psmisc package."
    fi
    echo
}

show_load() {
    print_statements="\n"
    load_vals=$(uptime | awk -F 'load average: ' '{ print $2 }' | sed 's/^ *//')
    
    IFS=', ' read -r load1 load5 load15 <<< "$load_vals"

    print_statements+="$(print_metric "1min : " "$load1" "$DEFAULT_LOAD_AVERAGE" "over" "Load average is too high" "PROCESS")\n"
    print_statements+="$(print_metric "5min : " "$load5" "$DEFAULT_LOAD_AVERAGE" "over" "Load average is too high" "PROCESS")\n"
    print_statements+="$(print_metric "15min: " "$load15" "$DEFAULT_LOAD_AVERAGE" "over" "Load average is too high" "PROCESS")\n"

    echo -e "$print_statements"
}

# Function to get top processes
get_top_processes_cpu() {
    process_tree_cpu=""
    while IFS= read -r line; do
        read -r user pid cpu path <<<"$line"
        normalized_cpu=$(awk -v c="$cpu" -v d="$DEFAULT_LOAD_AVERAGE" 'BEGIN { printf "%.2f", c / d }')
        process_tree_cpu+="$(print_metric "${user} (%)" "$normalized_cpu" $DEFAULT_PROCESS_CPU_THRESHOLD "over" "Process ${pid} is using a lot of compute power" "PROCESS")  PID: $pid  $path\n"
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
        process_tree_mem+="$(print_metric "${user} (%)" "$mem" $DEFAULT_PROCESS_MEM_THRESHOLD "over" "Process ${pid} is using a lot of memory" "PROCESS")  PID: $pid  $path\n"
    done < <(ps aux --sort=-%mem | grep -v "[p]s aux" | head -21 | tail -20 | awk '{
        cmd="";
        for(i=11;i<=NF;i++) cmd=cmd $i (i==NF ? "" : " ");
        printf "%s %s %s %s\n", $1, $2, $4, $11
    }')
    echo -e "$process_tree_mem"
}