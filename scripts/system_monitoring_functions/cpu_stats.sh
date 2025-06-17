#!/bin/bash
show_cpu_wait_steal() {
    echo -e "=== CPU Wait and Steal Times ==="
    echo "iowait: Percentage of time CPU waits for disk I/O to complete."
    echo "steal: Percentage of time CPU cycles were stolen by the hypervisor (virtualization)."
    if command -v mpstat &>/dev/null; then
        mpstat 1 1 | awk '/^Average:/ { printf "iowait: %s%%, steal: %s%%\n", $5, $6 }'
    else
        echo "mpstat not found. Please install the sysstat package."
    fi
    echo
}
