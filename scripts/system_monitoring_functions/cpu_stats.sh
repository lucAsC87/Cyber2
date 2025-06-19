get_average_cpu_stats() {
    local print_statements=""

    if ! command -v mpstat &>/dev/null; then
        echo -e "${COLOR_ABOVE_THRESHOLD}mpstat not found. Please install the sysstat package.${COLOR_RESET}"
        return
    fi

    # Extract overall average stats (line with "all")
    local cpu_stats
    cpu_stats=$(mpstat 1 1 | awk '/^Average:/ && $2 == "all" {print}')
    read -r _ _ usr nice sys iowait irq soft steal guest gnice idle <<<"$cpu_stats"
    total=$(awk -v idle="$idle" 'BEGIN { printf "%.2f", 100 - idle }')

    print_statements+="\n${BOLD}$(print_metric "Total (%)" "$total" $DEFAULT_CPU_TOTAL_THRESHOLD "over" "CPU usage is high; may be overloaded")\n"
    print_statements+="$(print_metric "usr (%)" "$usr" $DEFAULT_CPU_USR_THRESHOLD "over" "Too much user-space processing")\n"
    print_statements+="$(print_metric "nice (%)" "$nice" $DEFAULT_CPU_NICE_THRESHOLD "over" "Too many low-priority background jobs")\n"
    print_statements+="$(print_metric "sys (%)" "$sys" $DEFAULT_CPU_SYS_THRESHOLD "over" "Excessive system/kernel activity")\n"
    print_statements+="$(print_metric "iowait (%)" "$iowait" $DEFAULT_CPU_IOWAIT_THRESHOLD "over" "Waiting too long on disk or I/O")\n"
    print_statements+="$(print_metric "irq (%)" "$irq" $DEFAULT_CPU_IRQ_THRESHOLD "over" "Too many hardware interrupts")\n"
    print_statements+="$(print_metric "soft (%)" "$soft" $DEFAULT_CPU_SOFT_THRESHOLD "over" "Too many software interrupts")\n"
    print_statements+="$(print_metric "steal (%)" "$steal" $DEFAULT_CPU_STEAL_THRESHOLD "over" "Other VMs are stealing CPU time")\n"
    print_statements+="$(print_metric "guest (%)" "$guest" $DEFAULT_CPU_GUEST_THRESHOLD "over" "Unusual guest CPU usage")\n"
    print_statements+="$(print_metric "gnice (%)" "$gnice" $DEFAULT_CPU_GNICE_THRESHOLD "over" "Unusual guest nice usage")\n"
    print_statements+="$(print_metric "idle (%)" "$idle" $DEFAULT_CPU_IDLE_THRESHOLD "under" "Low idle means CPU is heavily loaded")\n"

    echo -e "$print_statements"
}

get_all_cpu_stats() {
    if ! command -v mpstat &>/dev/null; then
        echo -e "${COLOR_ABOVE_THRESHOLD}mpstat not found. Please install the sysstat package.${COLOR_RESET}"
        return
    fi

    local print_statements=""
    while IFS= read -r line; do
        read -r cpu_id usr nice sys iowait irq soft steal guest gnice idle <<<"$line"
        total=$(awk -v i="$idle" 'BEGIN { printf "%.2f", 100 - i }')

        print_statements+="\n${BOLD}Core $cpu_id:\n"
        print_statements+="${BOLD}$(print_metric "Total (%)" "$total" $DEFAULT_CPU_TOTAL_THRESHOLD "over" "High usage on Core $cpu_id")  "
        print_statements+="$(print_metric "usr (%)" "$usr" $DEFAULT_CPU_USR_THRESHOLD "over" "High usr on Core $cpu_id")  "
        print_statements+="$(print_metric "nice (%)" "$nice" $DEFAULT_CPU_NICE_THRESHOLD "over" "High nice on Core $cpu_id")  "
        print_statements+="$(print_metric "sys (%)" "$sys" $DEFAULT_CPU_SYS_THRESHOLD "over" "High sys on Core $cpu_id")  "
        print_statements+="$(print_metric "iowait (%)" "$iowait" $DEFAULT_CPU_IOWAIT_THRESHOLD "over" "High iowait on Core $cpu_id")  "
        print_statements+="$(print_metric "irq (%)" "$irq" $DEFAULT_CPU_IRQ_THRESHOLD "over" "High irq on Core $cpu_id")  "
        print_statements+="$(print_metric "soft (%)" "$soft" $DEFAULT_CPU_SOFT_THRESHOLD "over" "High soft on Core $cpu_id")  "
        print_statements+="$(print_metric "steal (%)" "$steal" $DEFAULT_CPU_STEAL_THRESHOLD "over" "High steal on Core $cpu_id")  "
        print_statements+="$(print_metric "guest (%)" "$guest" $DEFAULT_CPU_GUEST_THRESHOLD "over" "Unusual guest usage")  "
        print_statements+="$(print_metric "gnice (%)" "$gnice" $DEFAULT_CPU_GNICE_THRESHOLD "over" "Unusual gnice usage")  "
        print_statements+="$(print_metric "idle (%)" "$idle" $DEFAULT_CPU_IDLE_THRESHOLD "under" "Low idle on Core $cpu_id")\n"
    done < <(mpstat -P ALL 1 1 | awk '/^Average:/ && $2 != "all" && $2 != "CPU" {
        print $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
    }')

    echo -e "$print_statements"
}