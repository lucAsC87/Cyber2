#!/bin/bash

# Set the log file paths
LOG_HISTORY_FILE=/var/log/apt/history.log

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create output directory
OUTPUT_DIR="log"
mkdir -p "$OUTPUT_DIR"

while true; do
    clear  # Clear the screen before each iteration

    # Check if log files exist
    if [ ! -f "$LOG_HISTORY_FILE" ]; then
        echo -e "${RED}Error: History log file not found${NC}"
        exit 1
    fi

    # Print fancy header
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Log Analysis in Progress         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

    # Process history log silently
    total_entries=$(wc -l < "$LOG_HISTORY_FILE")
    error_count=$(grep -ci "error" "$LOG_HISTORY_FILE")
    grep -i "error" "$LOG_HISTORY_FILE" | tail -n 5 > "$OUTPUT_DIR/history_report.txt"

    # Process system error logs silently
    sudo journalctl -p err --no-pager | tail -n 5 > "$OUTPUT_DIR/system_error_report.txt"

    # Create backups (overwrite existing ones)
    cp "$LOG_HISTORY_FILE" "$OUTPUT_DIR/history.backup"
    sudo journalctl -p err --no-pager > "$OUTPUT_DIR/system_errors.backup"

    # Display beautiful summary
    echo -e "\n${GREEN}┌─────────────────────────────────┐${NC}"
    echo -e "${GREEN}│       Analysis Summary           │${NC}"
    echo -e "${GREEN}└─────────────────────────────────┘${NC}"

    echo -e "\n${BLUE}📊 Log Statistics${NC}"
    echo -e "   ${YELLOW}•${NC} Total Log Entries: $total_entries"
    echo -e "   ${YELLOW}•${NC} Total Error Events: $error_count"

    echo -e "\n${BLUE}📋 Report Details${NC}"
    echo -e "   ${YELLOW}•${NC} Full error analysis saved to reports"
    echo -e "   ${YELLOW}•${NC} System logs backed up successfully"
    echo -e "   ${YELLOW}•${NC} Historical data preserved"

    echo -e "\n${GREEN}✨ Analysis completed successfully! ✨${NC}"
    echo -e "\n${BLUE}📁 Reports Location:${NC} $OUTPUT_DIR/"
    echo -e "${YELLOW}Generated Reports:${NC}"
    echo -e "   📄 history_report.txt"
    echo -e "   📄 system_error_report.txt"
    echo -e "   📄 history.backup"
    echo -e "   📄 system_errors.backup"

    sleep 10
done