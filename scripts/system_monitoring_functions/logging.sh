
# Centralized alert logging
log_alert() {
    local severity="$1"
    local metric="$2"
    local value="$3"
    local threshold="$4"
    local message="$5"

    local timestamp
    timestamp=$(date '+%F %T')
    echo "$timestamp - $severity - METRIC: $metric - VALUE: $value - THRESHOLD: $threshold - MESSAGE: $message" >> "$LOG_FILE"
}

# Print metric and log alert immediately if violated
print_metric() {
    local name="$1" value="$2" threshold="$3" condition="$4" message="$5"
    local color="$COLOR_BELOW_THRESHOLD"
    local violated=0
    local is_bold=""
    local unit=""
    local clean_name="$name"

    # Extract unit using sed
    if [[ "$name" == *"("*")" ]]; then
        clean_name=$(echo "$name" | sed -E 's/^(.*)\s+\(([^)]+)\)$/\1/')
        unit=$(echo "$name" | sed -E 's/^(.*)\s+\(([^)]+)\)$/\2/')
    fi

    # Threshold checks
    if [[ "$condition" == "over" && $(echo "$value > $threshold" | bc -l) -eq 1 ]]; then
        color="$COLOR_ABOVE_THRESHOLD"
        violated=1
    elif [[ "$condition" == "under" && $(echo "$value < $threshold" | bc -l) -eq 1 ]]; then
        color="$COLOR_ABOVE_THRESHOLD"
        violated=1
    fi

    (( violated )) && {
        log_alert "WARNING" "$name" "$value" "$threshold" "$message"
    }

    [[ "$clean_name" == "Total" ]] && is_bold="${BOLD}"

    # Final formatted output
    printf "${COLOR_TEXT}${is_bold}%s:${COLOR_RESET} ${color}${is_bold}%.2f%s${COLOR_RESET}" \
        "$clean_name" "$value" "$unit"
}

log_hardware_warning() {
    local category="$1"
    local key="$2"
    local message="$3"
    echo -e "${category^^} WARNING$: $key: $message ($(date '+%F %T'))" >> "$LOG_FILE"
}

is_over() { awk -v v1="$1" -v v2="$2" 'BEGIN { exit (v1 > v2) ? 0 : 1 }'; }
is_under() { awk -v v1="$1" -v v2="$2" 'BEGIN { exit (v1 < v2) ? 0 : 1 }'; }