ui_get_logs(){
    clear
    tput civis                          # Hide the cursor
    trap "tput cnorm; stty echo" EXIT   # Ensure cursor is restored when script exits

    # Start real time loop
    while true; do
        harlod=$(source "$PROJECT_DIR/scripts/monitor-log-files.sh")
        tput cup 0 0; tput ed   # Reset cursor position and clear screen from cursor down
        echo "$harlod"
        echo -e "\nPress [Enter] to exit LOGS monitoring."
        read -t 1 -s input && [[ -z "$input" ]] && break    # Exit if Enter pressed
    done
    tput cnorm  # Restore cursor visibility
}