#!/bin/bash
export LC_ALL=C

if ! command -v netstat &> /dev/null; then
	echo "Error, install netstat with: sudo apt-get install net-tools"
	exit 1
fi

echo "Active network interfaces:"
awk -F: '/:/ {print $1}' /proc/net/dev | tail -n +3 | sed 's/ //g'

echo -n "Select network interface: "
read IFACE

if ! grep -q "^ *$IFACE:" /proc/net/dev; then
    echo "Interface $IFACE not found!"
    exit 1
fi

echo "Monitoring on $IFACE started. Press CTRL+C to stop."

# Function to show traffic
show_traffic() {
    local iface="$1"
    local old_rx=$(awk -v i="^ *$iface:" '$0 ~ i {print $2}' /proc/net/dev)
    local old_tx=$(awk -v i="^ *$iface:" '$0 ~ i {print $10}' /proc/net/dev)
    sleep 1
    while true; do
        local rx=$(awk -v i="^ *$iface:" '$0 ~ i {print $2}' /proc/net/dev)
        local tx=$(awk -v i="^ *$iface:" '$0 ~ i {print $10}' /proc/net/dev)
        local rx_diff=$((rx - old_rx))
        local tx_diff=$((tx - old_tx))
        rx_kb=$(echo "scale=2; $rx_diff/1024" | LC_NUMERIC=C bc)
        tx_kb=$(echo "scale=2; $tx_diff/1024" | LC_NUMERIC=C bc)
        rx_mb=$(echo "scale=2; $rx/1048576" | LC_NUMERIC=C bc)
        tx_mb=$(echo "scale=2; $tx/1048576" | LC_NUMERIC=C bc)
        printf "[%s] IN: %.2f KB/s | OUT: %.2f KB/s | Total: %.2f MB downloaded, %.2f MB uploaded\n" \
            "$(date '+%H:%M:%S')" "$rx_kb" "$tx_kb" "$rx_mb" "$tx_mb"
        old_rx=$rx
        old_tx=$tx
        sleep 1
    done
}

# Function to check suspicious connections
check_suspicious() {
    while true; do
        # Check connections on ports 22, 3389, 5900 (ssh, rdp, vnc)
        SUSP=$(netstat -nt | awk '$4 ~ /:22$|:3389$|:5900$/ && $6 == "ESTABLISHED"')
        if [[ -n "$SUSP" ]]; then
            PORTS=$(echo "$SUSP" | awk '{split($4, a, ":"); print a[length(a)]}' | sort -u | paste -sd "," -)
            logger "HIDS ALERT: Suspicious connection detected on port(s): $PORTS"
            echo "[ALERT] $(date '+%H:%M:%S') Suspicious connection detected on port(s): $PORTS"
        fi
        sleep 5
    done
}

# Start both functions in background
show_traffic "$IFACE" &
check_suspicious &

# Wait for manual interruption
wait
