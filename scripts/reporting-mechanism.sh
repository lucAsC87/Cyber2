# Centralized alert logging function
log_alert() {
    local severity="$1"       # Severity level (e.g., WARNING)
    local metric="$2"         # Name of the metric being checked (e.g., CPU, Memory)
    local value="$3"          # Current value of the metric
    local threshold="$4"      # Threshold that was violated
    local message="$5"        # Description or alert message

    # Get current timestamp in YYYY-MM-DD HH:MM:SS format
    local timestamp
    timestamp=$(date '+%F %T')

    # Remove any existing log line with the same message from the recent log file
    sed -i "/MESSAGE: $message/d" "$RECENT_LOG_FILE"

    # Append formatted log line to recent log file
    echo "$timestamp - $severity - METRIC: $metric - VALUE: $value - THRESHOLD: $threshold - MESSAGE: $message" >> "$RECENT_LOG_FILE"

    # Also append it to the main persistent log file
    echo "$timestamp - $severity - METRIC: $metric - VALUE: $value - THRESHOLD: $threshold - MESSAGE: $message" >> "$LOG_FILE"
}



# Function to print a metric in colored, formatted output, and optionally log an alert
print_metric() {
    local name="$1"           # Display name (includes unit in parentheses)
    local value="$2"          # Current value of the metric
    local threshold="$3"      # Threshold for triggering alert
    local condition="$4"      # Comparison condition: "over" or "under"
    local message="$5"        # Message to log if condition is violated
    local metric="$6"         # Metric identifier (for logging purposes)

    local color="$COLOR_BELOW_THRESHOLD"   # Default color (green)
    local violated=0                       # Flag to indicate if threshold was violated
    local is_bold=""                       # Bold styling for certain metrics
    local unit=""                          # Optional unit string
    local clean_name="$name"               # Name without unit

    # Extract unit if present in parentheses (e.g., "CPU (%)")
    if [[ "$name" == *"("*")" ]]; then
        clean_name=$(echo "$name" | sed -E 's/^(.*)\s+\(([^)]+)\)$/\1/')  # Name without unit
        unit=$(echo "$name" | sed -E 's/^(.*)\s+\(([^)]+)\)$/\2/')        # Extracted unit
    fi

    # Check if the metric violates the threshold
    if [[ "$condition" == "over" && $(echo "$value > $threshold" | bc -l) -eq 1 ]]; then
        color="$COLOR_ABOVE_THRESHOLD"  # Use alert color
        violated=1
    elif [[ "$condition" == "under" && $(echo "$value < $threshold" | bc -l) -eq 1 ]]; then
        color="$COLOR_ABOVE_THRESHOLD"
        violated=1
    fi

    # If threshold is violated, log the alert
    (( violated )) && {
        log_alert "WARNING" "$metric" "$value $unit" "$threshold $unit" "$message"
    }

    # Highlight "Total" metrics in bold
    [[ "$clean_name" == "Total" ]] && is_bold="${BOLD}"

    # Print formatted and colorized output for the metric
    printf "${COLOR_TEXT}${is_bold}%s:${COLOR_RESET} ${color}${is_bold}%.2f %s${COLOR_RESET}" \
    "$clean_name" "$value" "$unit"
}