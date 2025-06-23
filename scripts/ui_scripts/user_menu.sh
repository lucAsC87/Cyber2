ui_get_logs(){
    clear
    tput civis
    trap "tput cnorm; stty echo" EXIT
    while true; do
        harlod=$(source "$PROJECT_DIR/scripts/monitor-log-files.sh")
        tput cup 0 0; tput ed
        echo "$harlod"
        echo -e "\nPress [Enter] to exit LOGS monitoring."
        read -t 1 -s input && [[ -z "$input" ]] && break
    done
    tput cnorm
}