choose_interface() {
    export LC_ALL=C
    while true; do
        echo "Active network interfaces:" >&2
        awk -F':' 'NR > 2 {gsub(/ /, "", $1); print $1}' /proc/net/dev >&2

        echo -en "\nSelect network interface: " >&2
        read iface

        if grep -q "^ *$iface:" /proc/net/dev; then
            echo "$iface"
            return
        else
            echo "Interface $iface not found! Try again." >&2
        fi
    done
}

# Function to show traffic
show_traffic() {
    local iface="$1"
    local old_rx=$(awk -v i="^ *$iface:" '$0 ~ i {print $2}' /proc/net/dev)
    local old_tx=$(awk -v i="^ *$iface:" '$0 ~ i {print $10}' /proc/net/dev)
    sleep 1

    local rx=$(awk -v i="^ *$iface:" '$0 ~ i {print $2}' /proc/net/dev)
    local tx=$(awk -v i="^ *$iface:" '$0 ~ i {print $10}' /proc/net/dev)
    local rx_diff=$((rx - old_rx))
    local tx_diff=$((tx - old_tx))
    rx_kb=$(echo "scale=2; $rx_diff/1024" | LC_NUMERIC=C bc)
    tx_kb=$(echo "scale=2; $tx_diff/1024" | LC_NUMERIC=C bc)
    rx_mb=$(echo "scale=2; $rx/1048576" | LC_NUMERIC=C bc)
    tx_mb=$(echo "scale=2; $tx/1048576" | LC_NUMERIC=C bc)

    echo
    printf "[%s] " "$(date '+%H:%M:%S')"
    print_metric "Download (KB/s)" "$rx_kb" "$DEFAULT_DOWNLOAD_THRESHOLD" "over" "Suspicious download on the network: incoming traffic above threshold" "NETWORK"
    echo -n " | "
    print_metric "Upload (KB/s)" "$tx_kb" "$DEFAULT_UPLOAD_THRESHOLD" "over" "Suspicious upload on the network: outgoing traffic above threshold" "NETWORK"
    echo -n " | "
    print_metric "Total Downloaded (MB)" "$rx_mb" 0 "" "" "TRAFFIC"
    echo -n " | "
    print_metric "Total Uploaded (MB)" "$tx_mb" 0 "" "" "TRAFFIC"
    echo


    old_rx=$rx
    old_tx=$tx
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
    local ports_regex=$(echo "$MONITOR_PORTS" | sed 's/ /|/g')

    SUSP=$(ss -ntp state established | awk -v regex=":($ports_regex)( |$)" '{if ($4 ~ regex || $5 ~ regex) print $0}')
    if [[ -n "$SUSP" ]]; then
        echo
        echo "Suspicious connections detected:"
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

            # Log alert
            logger "HIDS ALERT: $local_ip:$local_port -> $remote_ip:$remote_port PID=$pid PROC=$pname"

            # Use print_metric to display suspicious connection
            print_metric "Suspicious Connection" 1 0 "over" "Connection to monitored port detected: $local_ip:$local_port -> $remote_ip:$remote_port (PID $pid, PROC $pname)" "NETWORK"
            echo
        done
    else
        echo
        echo "No suspicious connections found."
    fi
}

# Start both functions in background
#show_traffic "$IFACE" &
#pid_traffic=$!
#check_suspicious &
#pid_susp=$!

#cleanup() {
#    echo -e "\nInterruption requested, terminating all process..."
#    kill $pid_traffic $pid_susp 2>/dev/null
#    wait $pid_traffic $pid_susp 2>/dev/null
#    exit 0
#}
#trap cleanup SIGINT SIGTERM

