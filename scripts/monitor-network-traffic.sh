#!/bin/bash
export LC_ALL=C

echo "Active network interfaces:"
awk -F: '/:/ {print $1}' /proc/net/dev | tail -n +3 | sed 's/ //g'

echo -en "\nSelect network interface: "
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

# Ports to check (ssh, rdp, vnc)
# 21     - FTP (File Transfer Protocol)
# 22     - SSH (Secure Shell)
# 23     - Telnet (Remote Login)
# 25     - SMTP (Simple Mail Transfer Protocol)
# 53     - DNS (Domain Name System)
# 80     - HTTP (HyperText Transfer Protocol)
# 110    - POP3 (Post Office Protocol v3)
# 139    - NetBIOS Session Service (File/Print Sharing su Windows)
# 143    - IMAP (Internet Message Access Protocol)
# 445    - SMB (Server Message Block, File/Print Sharing su Windows)
# 3389   - RDP (Remote Desktop Protocol)
# 5900   - VNC (Virtual Network Computing)
# 3306   - MySQL Database Server
# 5432   - PostgreSQL Database Server
# 6379   - Redis Database
# 8080   - HTTP alternativo (usato da proxy/applicazioni web)
# 8443   - HTTPS alternativo
# 27017  - MongoDB Database Server
# 6667   - IRC (Internet Relay Chat)
# 5000   - Servizi vari/applicazioni di sviluppo (es. Flask)
# 12345  - NetBus (trojan/backdoor)
# 31337  - Elite/Back Orifice (backdoor/malware)
# 2323   - Alternative Telnet
MONITOR_PORTS="21 22 23 25 53 80 110 139 143 445 3389 5900 3306 5432 6379 8080 8443 27017 6667 5000 12345 31337 2323"

# Function to check suspicious connections
check_suspicious() {
    local ports_regex=$(echo $MONITOR_PORTS | sed 's/ /|/g')
    while true; do
        SUSP=$(ss -ntp state established | awk -v regex=":($ports_regex)( |$)" '{if ($4 ~ regex || $5 ~ regex) print $0}')
        if [[ -n "$SUSP" ]]; then
            echo "$SUSP" | while read -r line; do
                local_addr=$(echo "$line" | awk '{print $4}')
                remote_addr=$(echo "$line" | awk '{print $5}')
                proc_info=$(echo "$line" | grep -oP 'users:\(\(\K[^)]*')
                local_ip=$(echo "$local_addr" | awk -F: '{OFS=":"; for(i=1;i<NF;i++) printf $i (i==NF-1?OFS:"")}')
                local_port=$(echo "$local_addr" | awk -F: '{print $NF}')
                remote_ip=$(echo "$remote_addr" | awk -F: '{OFS=":"; for(i=1;i<NF;i++) printf $i (i==NF-1?OFS:"")}')
                remote_port=$(echo "$remote_addr" | awk -F: '{print $NF}')
                pid=$(echo "$proc_info" | grep -oP 'pid=\K[0-9]+')
                pname=$(echo "$proc_info" | awk -F',' '{print $1}' | tr -d '"')
				logger "HIDS ALERT: $local_ip:$local_port -> $remote_ip:$remote_port PID=$pid PROC=$pname"
                echo -e "\033[31m[ALERT] $(date '+%H:%M:%S') $local_ip:$local_port -> $remote_ip:$remote_port PID=$pid PROC=$pname\033[0m"
            done
        fi
        sleep 5
    done
}

# Start both functions in background
show_traffic "$IFACE" &
pid_traffic=$!
check_suspicious &
pid_susp=$!

cleanup() {
    echo -e "\nInterruption requested, terminating all process..."
    kill $pid_traffic $pid_susp 2>/dev/null
    wait $pid_traffic $pid_susp 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

wait
