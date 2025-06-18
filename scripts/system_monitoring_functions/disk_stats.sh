#!/bin/bash
get_disk_io_stats() {
    if ! command -v iostat &>/dev/null; then
        echo -e "${RED}iostat not found. Please install the sysstat package.${RESET}"
        return
    fi

    tput civis
    trap "tput cnorm; stty echo; return" EXIT

    while true; do
        tput cup 0 0
        echo -e "${BLUE}${BOLD}=== Real-Time Disk I/O Stats ===${RESET}"
        warnings=()

        iostat -dx 1 1 | awk '
            BEGIN { found = 0 }
            /^Device/ { found = 1; next }
            found && $1 ~ /^(sd|nvme|vd|hd)/ {
                device = $1
                rkbs = $3
                wkbs = $8
                util = $(NF)
                read_mb = rkbs / 1024
                write_mb = wkbs / 1024
                printf "%s %.2f %.2f %.2f\n", device, read_mb, write_mb, util
            }
        ' | while read -r dev read_mb write_mb util; do
            usage=$(awk -v u="$util" 'BEGIN { printf "%.2f", u }')
            color="$GREEN"
            if awk "BEGIN {exit !($usage > 70)}"; then
                color="$RED"
                warning="High disk usage on $dev (${usage}%%)"
                warnings+=("$warning")
                echo "$(date '+%F %T') - $warning" >> "$LOG_FILE"
            fi

            echo -en "${BROWN}Device ${dev}:${RESET} "
            echo -en "${BOLD}Read:${color} ${read_mb} MB/s${RESET} ${BROWN}|${RESET} "
            echo -en "${BOLD}Write:${color} ${write_mb} MB/s${RESET} ${BROWN}|${RESET} "
            echo -e "${BOLD}Util:${color} ${usage}%%${RESET}"
        done

        if (( ${#warnings[@]} > 0 )); then
            echo -e "\n${RED}${BOLD}Warnings:${RESET}"
            for w in "${warnings[@]}"; do
                echo -e "${RED}- $w${RESET}"
            done
        fi

        echo -e "\nPress [Enter] to exit real-time view."
        read -t 1 -s input && [[ -z "$input" ]] && break
    done
}

