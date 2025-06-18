get_disk_io_stats() {
    if ! command -v iostat &>/dev/null; then
        echo -e "${RED}iostat not found. Please install the sysstat package.${RESET}"
        return
    fi

    echo -e "${BLUE}${BOLD}=== Disk I/O Stats ===${RESET}"
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

        echo -en "${BROWN}Device:${RESET} ${dev}${RESET}  "
        echo -en "${BROWN}Read:${RESET} ${color}${read_mb} MB/s${RESET}  "
        echo -en "${BROWN}Write:${RESET} ${color}${write_mb} MB/s${RESET}  "
        echo -e "${BROWN}Util:${RESET} ${color}${usage}%%${RESET}"
    done

    echo -e "\n${BLUE}${BOLD}=== Disk Usage ===${RESET}"
    df -h --output=source,size,used,avail,pcent | grep -E '^(/dev/sd|/dev/nvme|/dev/vd|/dev/hd)' | while read -r source size used avail pcent; do
        echo -e "${BROWN}Device:${RESET} ${source}  " \
                "${BROWN}Size:${RESET} ${size}  " \
                "${BROWN}Used:${RESET} ${used}  " \
                "${BROWN}Avail:${RESET} ${avail}  " \
                "${BROWN}Usage:${RESET} ${pcent}"
    done

    if (( ${#warnings[@]} > 0 )); then
        echo -e "\n${RED}${BOLD}Warnings:${RESET}"
        for w in "${warnings[@]}"; do
            echo -e "${RED}- $w${RESET}"
        done
    fi
}


