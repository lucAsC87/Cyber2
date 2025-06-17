#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/system_monitoring_functions/cpu_stats.sh"
source "$(dirname "${BASH_SOURCE[0]}")/system_monitoring_functions/disk_io_stats.sh"
source "$(dirname "${BASH_SOURCE[0]}")/system_monitoring_functions/memory_stats.sh"
source "$(dirname "${BASH_SOURCE[0]}")/system_monitoring_functions/process_stats.sh"

# Interactive menu
while true; do
    clear
    echo "===================================="
    echo "   System Monitoring Tool (sysmon)"
    echo "===================================="
    echo "1) Load Average"
    echo "2) Disk I/O"
    echo "3) CPU Wait / Steal Time"
    echo "4) Swap Activity"
    echo "5) Process Hierarchy"
    echo "6) All Metrics"
    echo "q) Quit"
    echo -n "Select an option: "
    read -r choice

    case "$choice" in
        1) show_load ;;
        2) show_disk_io ;;
        3) show_cpu_wait_steal ;;
        4) show_swap ;;
        5) show_process_tree ;;
        6)
            show_load
            show_disk_io
            show_cpu_wait_steal
            show_swap
            show_process_tree
            ;;
        q|Q)
            echo "Exiting..."
            exit 0
            ;;
        *) echo "Invalid selection." ;;
    esac

    echo -n "Press [Enter] to continue..."
    read -r
done
