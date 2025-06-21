get_disk_io_stats() {
    if ! command -v iostat &>/dev/null; then
        echo -e "${COLOR_ABOVE_THRESHOLD}iostat not found. Please install the sysstat package.${COLOR_RESET}"
        return
    fi

    local print_statements=""

    while read -r dev read_mb write_mb util; do
        print_statements+="\n${BOLD}Device ${dev}:${COLOR_RESET}\n"
        print_statements+="$(print_metric "Read MB/s" "$read_mb" $DEFAULT_DISK_READ_THRESHOLD "over" "High read on $dev" "DISK")  "
        print_statements+="$(print_metric "Write MB/s" "$write_mb" $DEFAULT_DISK_WRITE_THRESHOLD "over" "High write on $dev" "DISK")  "
        print_statements+="$(print_metric "Util (%)" "$util" $DEFAULT_DISK_TPS_THRESHOLD "over" "High utilization on $dev" "DISK")${COLOR_RESET}\n"
    done < <(
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
        '
    )

    echo -e "$print_statements"
}

get_disk_usage() {
    local print_statements=""

    while read -r source size used avail pcent; do
        usage_val="${pcent%%%}"  # Strip the %

        size_gb=$(awk -v kb="$size" 'BEGIN { printf "%.2f", kb / 1024 / 1024 }')
        used_gb=$(awk -v kb="$used" 'BEGIN { printf "%.2f", kb / 1024 / 1024 }')
        avail_gb=$(awk -v kb="$avail" 'BEGIN { printf "%.2f", kb / 1024 / 1024 }')

        print_statements+="\n${BOLD}Device ${source}:${COLOR_RESET}\n"
        print_statements+="$(print_metric "Size (GB)" "$size_gb" 0 "none" "")  "
        print_statements+="$(print_metric "Used (GB)" "$used_gb" 0 "none" "")  "
        print_statements+="$(print_metric "Avail (GB)" "$avail_gb" 0 "none" "")  "
        print_statements+="$(print_metric "Usage (%)" "$usage_val" $DEFAULT_DISK_THRESHOLD "over" "Disk almost full: $source" "DISK")${COLOR_RESET}\n"
    done < <(
        df --block-size=1K --output=source,size,used,avail,pcent |
        grep -E '^(/dev/sd|/dev/nvme|/dev/vd|/dev/hd)'
    )

    echo -e "$print_statements"
}

