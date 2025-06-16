#!/bin/bash

# Set the log file paths
LOG_HISTORY_FILE=/var/log/apt/history.log

# Check if log files exist
if [ ! -f "$LOG_HISTORY_FILE" ]; then
    echo "Error: History log file not found"
    exit 1
fi

# Create output directory
OUTPUT_DIR="log_analysis"
mkdir -p "$OUTPUT_DIR"

# Extract logs and generate statistics
echo "Processing logs..."

# Process history log
{
    echo "=== History Log Analysis ==="
    echo "Total entries: $(wc -l < "$LOG_HISTORY_FILE")"
    echo "Error entries: $(grep -ci "error" "$LOG_HISTORY_FILE")"
    echo -e "\nRecent Errors:"
    grep -i "error" "$LOG_HISTORY_FILE" | tail -n 5
} > "$OUTPUT_DIR/history_report.txt"

# Process system error logs using journalctl
{
    echo "=== System Error Log Analysis ==="
    echo "Recent System Errors:"
    sudo journalctl -p err --no-pager | tail -n 5
} > "$OUTPUT_DIR/system_error_report.txt"

# Create backups
cp "$LOG_HISTORY_FILE" "$OUTPUT_DIR/history.backup"
sudo journalctl -p err --no-pager > "$OUTPUT_DIR/system_errors.backup"

echo "Analysis complete. Check $OUTPUT_DIR/ for reports"