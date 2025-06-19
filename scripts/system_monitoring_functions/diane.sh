#!/bin/bash

# =======================================
# HIDS Toolkit - System Resource Monitor
# Monitors CPU, Memory, Disk, and Swap.
# =======================================

# Source the configuration file for thresholds and log paths
source "./toolkit/config.sh"

LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/system_alerts.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log alerts
log_alert() {
    local severity="$1" # e.g., "CRITICAL", "WARNING"
    local metric="$2"   # e.g., "CPU_TOTAL", "MEM_USAGE"
    local value="$3"    # The actual value observed
    local threshold="$4" # The threshold that was crossed
    local message="$5"  # Specific alert message

    local timestamp=$(date '+%F %T')
    echo "$timestamp - $severity - METRIC: $metric - VALUE: $value - THRESHOLD: $threshold - MESSAGE: $message" | tee -a "$LOG_FILE"
}

# Function to check CPU utilization
check_cpu_utilization() {
    # Check if mpstat is available
    if ! command -v mpstat &>/dev/null; then
        log_alert "ERROR" "PREREQUISITE" "N/A" "mpstat" "mpstat command not found. Please install sysstat package."
        return
    fi

    # Get CPU stats for the last second
    # Use 'grep Average' to get the summary line
    local cpu_stats=$(mpstat 1 1 | awk '/Average:/ {print}')

    # Extract values, ensure locale doesn't mess up decimal points
    # Read the fields into variables, ignoring the first two
    read -r _ _ usr nice sys iowait irq soft steal guest gnice idle <<< "$cpu_stats"

    # Convert to numeric values, handling potential comma decimals for awk/bc
    usr=$(echo "$usr" | tr ',' '.')
    nice=$(echo "$nice" | tr ',' '.')
    sys=$(echo "$sys" | tr ',' '.')
    iowait=$(echo "$iowait" | tr ',' '.')
    irq=$(echo "$irq" | tr ',' '.')
    soft=$(echo "$soft" | tr ',' '.')
    steal=$(echo "$steal" | tr ',' '.')
    guest=$(echo "$guest" | tr ',' '.')
    gnice=$(echo "$gnice" | tr ',' '.')
    idle=$(echo "$idle" | tr ',' '.')

    # Calculate total CPU usage (100 - idle)
    local total_cpu=$(awk -v i="$idle" 'BEGIN { printf "%.2f", 100 - i }')

    # Compare against configured thresholds (from config.sh)
    # CPU Total
    if (( $(echo "$total_cpu >= $DEFAULT_CPU_TOTAL_THRESHOLD" | bc -l) )); then
        log_alert "CRITICAL" "CPU_TOTAL_USAGE" "$total_cpu%" "$DEFAULT_CPU_TOTAL_THRESHOLD%" "Overall CPU usage is high."
    fi

    # CPU User
    if (( $(echo "$usr >= $DEFAULT_CPU_USR_THRESHOLD" | bc -l) )); then
        log_alert "WARNING" "CPU_USR_USAGE" "$usr%" "$DEFAULT_CPU_USR_THRESHOLD%" "User CPU usage is high."
    fi

    # CPU Nice
    if (( $(echo "$nice >= $DEFAULT_CPU_NICE_THRESHOLD" | bc -l) )); then
        log_alert "WARNING" "CPU_NICE_USAGE" "$nice%" "$DEFAULT_CPU_NICE_THRESHOLD%" "Nice CPU usage is high."
    fi

    # CPU System
    if (( $(echo "$sys >= $DEFAULT_CPU_SYS_THRESHOLD" | bc -l) )); then
        log_alert "WARNING" "CPU_SYS_USAGE" "$sys%" "$DEFAULT_CPU_SYS_THRESHOLD%" "System CPU usage is high."
    fi

    # CPU I/O Wait
    if (( $(echo "$iowait >= $DEFAULT_CPU_IOWAIT_THRESHOLD" | bc -l) )); then
        log_alert "CRITICAL" "CPU_IOWAIT" "$iowait%" "$DEFAULT_CPU_IOWAIT_THRESHOLD%" "CPU is spending too much time waiting for I/O."
    fi

    # CPU IRQ
    if (( $(echo "$irq >= $DEFAULT_CPU_IRQ_THRESHOLD" | bc -l) )); then
        log_alert "WARNING" "CPU_IRQ" "$irq%" "$DEFAULT_CPU_IRQ_THRESHOLD%" "Hardware Interrupt CPU usage is high."
    fi

    # CPU SoftIRQ
    if (( $(echo "$soft >= $DEFAULT_CPU_SOFT_THRESHOLD" | bc -l) )); then
        log_alert "WARNING" "CPU_SOFTIRQ" "$soft%" "$DEFAULT_CPU_SOFT_THRESHOLD%" "Software Interrupt CPU usage is high."
    fi

    # CPU Steal (relevant in virtualized environments)
    if (( $(echo "$steal >= $DEFAULT_CPU_STEAL_THRESHOLD" | bc -l) )); then
        log_alert "CRITICAL" "CPU_STEAL" "$steal%" "$DEFAULT_CPU_STEAL_THRESHOLD%" "CPU 'stolen' by hypervisor is high. VM performance might be impacted."
    fi

    # CPU Guest (relevant in virtualized environments)
    if (( $(echo "$guest >= $DEFAULT_CPU_GUEST_THRESHOLD" | bc -l) )); then
        log_alert "WARNING" "CPU_GUEST" "$guest%" "$DEFAULT_CPU_GUEST_THRESHOLD%" "CPU usage by guest OS is high."
    fi

    # CPU Guest Nice (relevant in virtualized environments)
    if (( $(echo "$gnice >= $DEFAULT_CPU_GNICE_THRESHOLD" | bc -l) )); then
        log_alert "WARNING" "CPU_GNICE" "$gnice%" "$DEFAULT_CPU_GNICE_THRESHOLD%" "Niced guest CPU usage is high."
    fi

    # CPU Idle (alert if idle is too low)
    if (( $(echo "$idle <= $DEFAULT_CPU_IDLE_THRESHOLD" | bc -l) )); then
        log_alert "CRITICAL" "CPU_IDLE" "$idle%" "$DEFAULT_CPU_IDLE_THRESHOLD%" "CPU idle percentage is critically low."
    fi
}

# Function to check memory usage (RAM)
check_memory_usage() {
    # Get total and available memory in KB
    local mem_info=$(free -k | awk '/^Mem:/ {print $2, $7}') # $2 is total, $7 is available
    local total_mem=$(echo "$mem_info" | awk '{print $1}')
    local available_mem=$(echo "$mem_info" | awk '{print $2}')

    if [ -z "$total_mem" ] || [ -z "$available_mem" ] || [ "$total_mem" -eq 0 ]; then
        log_alert "ERROR" "MEMORY" "N/A" "N/A" "Could not retrieve memory information."
        return
    fi

    # Calculate used memory percentage
    # used_mem_kb = total_mem - available_mem
    # used_percent = (used_mem_kb / total_mem) * 100
    local used_mem_kb=$(awk "BEGIN {print $total_mem - $available_mem}")
    local mem_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($used_mem_kb / $total_mem) * 100}")

    if (( $(echo "$mem_usage_percent >= $DEFAULT_MEM_THRESHOLD" | bc -l) )); then
        log_alert "CRITICAL" "MEMORY_USAGE" "$mem_usage_percent%" "$DEFAULT_MEM_THRESHOLD%" "Memory usage is high."
    fi
}

# Function to check Swap Activity
check_swap_activity() {
    # Check if vmstat is available
    if ! command -v vmstat &>/dev/null; then
        log_alert "ERROR" "PREREQUISITE" "N/A" "vmstat" "vmstat command not found. Please install procps package."
        return
    fi

    # Get swap-in (si) and swap-out (so) rates for the last second
    local swap_stats=$(vmstat 1 2 | awk 'NR==4 {print $7, $8}') # $7 is si, $8 is so
    local si=$(echo "$swap_stats" | awk '{print $1}')
    local so=$(echo "$swap_stats" | awk '{print $2}')

    if [ -z "$si" ] || [ -z "$so" ]; then
        log_alert "ERROR" "SWAP_ACTIVITY" "N/A" "N/A" "Could not retrieve swap activity information."
        return
    fi

    # Compare against configured thresholds
    if (( $(echo "$si >= $DEFAULT_SWAP_SI_THRESHOLD" | bc -l) )); then
        log_alert "CRITICAL" "SWAP_IN" "${si} KB/s" "${DEFAULT_SWAP_SI_THRESHOLD} KB/s" "High swap-in activity detected."
    fi

    if (( $(echo "$so >= $DEFAULT_SWAP_SO_THRESHOLD" | bc -l) )); then
        log_alert "CRITICAL" "SWAP_OUT" "${so} KB/s" "${DEFAULT_SWAP_SO_THRESHOLD} KB/s" "High swap-out activity detected."
    fi
}

# Function to check disk usage (percentage full)
check_disk_usage() {
    # Exclude snap and loop devices, and specific filesystem types
    local disk_usage=$(df -hP | awk 'NR==1{next} /^\/dev\// {gsub(/%/, "", $5); print $1, $5}' | grep -E '^(ext|xfs|btrfs|zfs|/dev/sd|/dev/hd|/dev/nvme|/dev/vd)' | grep -v 'loop' | grep -v 'snap')

    if [ -z "$disk_usage" ]; then
        log_alert "WARNING" "DISK_USAGE" "N/A" "N/A" "Could not retrieve disk usage information for primary partitions."
        return
    fi

    while read -r device usage_percent; do
        if (( $(echo "$usage_percent >= $DEFAULT_DISK_THRESHOLD" | bc -l) )); then
            log_alert "CRITICAL" "DISK_USAGE" "$device ($usage_percent%)" "$DEFAULT_DISK_THRESHOLD%" "Disk space on $device is critically low."
        fi
    done <<< "$disk_usage"
}

# Function to check Disk I/O activity (Read/Write MB/s, TPS)
check_disk_io() {
    # Check if iostat is available
    if ! command -v iostat &>/dev/null; then
        log_alert "ERROR" "PREREQUISITE" "N/A" "iostat" "iostat command not found. Please install sysstat package."
        return
    F
    fi

    # Get disk I/O stats for the last interval (1 second sample, 2 iterations, take the 2nd interval)
    # Filter for actual disk devices (e.g., sd, hd, nvme, vd), exclude 'loop' and 'dm-' devices
    local io_stats=$(iostat -d -k 1 2 | awk 'NR>HEADER_LINE && /^[svh]d[a-z][0-9]*|^nvme[0-9]+n[0-9]+|^vd[a-z][0-9]*/ { if(NR != prev_NR + 1) { HEADER_LINE=NR } else { print $1, $3, $4, $5 } } {prev_NR=NR}')

    if [ -z "$io_stats" ]; then
        log_alert "WARNING" "DISK_IO" "N/A" "N/A" "Could not retrieve disk I/O information."
        return
    fi

    # Process the 'Last Interval' data for each relevant device
    # We run iostat 1 2 and take the second block of device stats
    echo "$io_stats" | while read -r device rkB_s wkB_s tps; do
        # Convert KB/s to MB/s
        local rMB_s=$(awk "BEGIN {printf \"%.2f\", $rkB_s / 1024}")
        local wMB_s=$(awk "BEGIN {printf \"%.2f\", $wkB_s / 1024}")
        local tps_val=$(awk "BEGIN {printf \"%.2f\", $tps}")

        if (( $(echo "$rMB_s >= $DEFAULT_DISK_READ_THRESHOLD" | bc -l) )); then
            log_alert "CRITICAL" "DISK_READ" "$device ($rMB_s MB/s)" "${DEFAULT_DISK_READ_THRESHOLD} MB/s" "High disk read activity on $device."
        fi

        if (( $(echo "$wMB_s >= $DEFAULT_DISK_WRITE_THRESHOLD" | bc -l) )); then
            log_alert "CRITICAL" "DISK_WRITE" "$device ($wMB_s MB/s)" "${DEFAULT_DISK_WRITE_THRESHOLD} MB/s" "High disk write activity on $device."
        fi

        if (( $(echo "$tps_val >= $DEFAULT_DISK_TPS_THRESHOLD" | bc -l) )); then
            log_alert "WARNING" "DISK_TPS" "$device ($tps_val TPS)" "${DEFAULT_DISK_TPS_THRESHOLD} TPS" "High disk transfers per second on $device."
        fi
    done
}

# Main monitoring loop
monitor_resources() {
    while true; do
        check_cpu_utilization
        check_memory_usage
        check_swap_activity
        check_disk_usage    # NEW: Call disk usage check
        check_disk_io       # NEW: Call disk I/O check

        # Sleep for a defined interval (e.g., every 5 minutes)
        # For a HIDS, this interval might be shorter (e.g., 30-60 seconds)
        sleep 300 # Sleeps for 5 minutes
    done
}

# Start monitoring
monitor_resources
