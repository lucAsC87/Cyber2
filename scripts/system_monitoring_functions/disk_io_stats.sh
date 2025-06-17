#!/bin/bash
show_disk_io() {
    echo -e "=== Disk I/O (MB/s) ==="
    echo "Shows disk read/write rates and transfer rates per second."
    echo "Read/Write are data rates in megabytes per second (MB/s)."
    echo "TPS (Transfers Per Second) indicates the number of IO operations per second."
    if command -v iostat &>/dev/null; then
        iostat 1 2 | awk '
            /^Device/ {
                header_line=NR
                if (!seen_first) {
                    label = "Since Boot:"
                    seen_first=1
                } else {
                    label = "Last Interval:"
                }
                next
            }
            NR > header_line {
                if ($1 ~ /^(hd|sd|nvme|vd)[a-z0-9]*$/) {
                    read_mb = $3 / 1024
                    write_mb = $4 / 1024
                    printf "%s %s - Read: %.2f MB/s, Write: %.2f MB/s, TPS: %.2f\n", label, $1, read_mb, write_mb, $2
                }
            }
        '
    else
        echo "iostat not found. Please install the sysstat package."
    fi
    echo
}