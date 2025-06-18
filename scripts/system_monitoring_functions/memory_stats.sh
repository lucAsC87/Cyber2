get_memory_stats() {
    if ! command -v free &>/dev/null; then
        echo -e "${RED}free not found. Please install procps or equivalent.${RESET}"
        return
    fi

    # Collect memory and swap stats (in MB)
    read -r _ total used free shared buff_cache available <<< \
        $(free -m | awk '/^Mem:/ {print $1, $2, $3, $4, $5, $6}')
    read -r _ swap_total swap_used swap_free <<< \
        $(free -m | awk '/^Swap:/ {print $1, $2, $3, $4}')

    mem_usage_pct=$(awk -v u=$used -v t=$total 'BEGIN { printf "%.2f", (u / t) * 100 }')
    swap_usage_pct=$(awk -v u=$swap_used -v t=$swap_total 'BEGIN { if (t==0) print 0; else printf "%.2f", (u / t) * 100 }')

    declare -A warnings
    is_over() { awk -v v1="$1" -v v2="$2" 'BEGIN { exit (v1 > v2) ? 0 : 1 }'; }
    is_under() { awk -v v1="$1" -v v2="$2" 'BEGIN { exit (v1 < v2) ? 0 : 1 }'; }

    print_metric() {
        local name=$1 value=$2 unit=$3 threshold=$4 condition=$5 explain=$6
        local color="$GREEN"
        local violated=0

        if [[ "$condition" == "over" ]]; then
            if is_over "$value" "$threshold"; then
                color="$RED"
                violated=1
            fi
        elif [[ "$condition" == "under" ]]; then
            if is_under "$value" "$threshold"; then
                color="$RED"
                violated=1
            fi
        fi

        echo -e "  ${BROWN}${name}:${RESET} ${color}${value}${unit}${RESET}"
        (( violated )) && warnings["$name"]="$explain"
    }

    echo -e "${BOLD}${BLUE}=== Real-Time Memory & Swap Usage ===${RESET}"
    print_metric "Total RAM" "$total" " MB" 0 "" ""
    print_metric "Used RAM" "$used" " MB" 0 "" ""
    print_metric "Free RAM" "$free" " MB" 300 "under" "Low free memory; consider closing apps"
    print_metric "RAM Usage" "$mem_usage_pct" "%" 85 "over" "High RAM usage"
    echo
    print_metric "Total Swap" "$swap_total" " MB" 0 "" ""
    print_metric "Used Swap" "$swap_used" " MB" 0 "" ""
    print_metric "Free Swap" "$swap_free" " MB" 100 "under" "Low swap space left"
    print_metric "Swap Usage" "$swap_usage_pct" "%" 50 "over" "High swap usage; system may be swapping"

    if (( ${#warnings[@]} > 0 )); then
        echo -e "\n${RED}${BOLD}Warnings:${RESET}"
        for key in "${!warnings[@]}"; do
            echo -e "${RED}- $key: ${warnings[$key]}${RESET}"
            echo "Memory Warning: $key: ${warnings[$key]} ($(date '+%F %T'))" >> "$LOG_FILE"
        done
    fi
}
