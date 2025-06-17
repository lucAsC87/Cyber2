#!/bin/bash
show_swap() {
    echo -e "=== Swap Activity ==="
    echo "si: Swap-in rate - how much data (KB/s) is moved from swap space into RAM."
    echo "so: Swap-out rate - how much data (KB/s) is moved from RAM into swap space."
    if command -v vmstat &>/dev/null; then
        vmstat 1 2 | awk 'NR==4 { printf "si: %s KB/s, so: %s KB/s\n", $7, $8 }'
    else
        echo "vmstat not found. Please install the procps package."
    fi
    echo
}