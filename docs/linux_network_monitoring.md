## Monitor the Network Traffic on Linux

Linux has at its disposal a plethora of tools to monitor network traffic. Among the most commonly used are:

- **ifconfig:** Displays and configures network interface parameters. Useful for checking the status and statistics of network interfaces.
- **ip:** The modern replacement for ifconfig. It manages and displays IP addresses, routes, and more, and can show real-time packet statistics.
- **netstat:** Checks for connections to unknown IP addresses or unusual ports, displaying network connections, routing tables, and interface statistics.
- **ss:** Modern replacement for netstat for displaying socket statistics and active network connections.
- **iftop:** Monitors real-time bandwidth usage and shows which hosts are sending or receiving the most data.
- **nload:** Provides a simple, real-time graphical representation of incoming and outgoing network traffic on the terminal.
- **bmon:** (Bandwidth Monitor) Shows bandwidth usage on all network interfaces in a graphical, terminal-based interface.
- **vnstat:** Useful for tracking historical network traffic statistics and detecting if unusual amounts of data are being sent to other networks.
- **tcpdump:** Can capture and analyze the traffic to or from a specific port or IP address.
- **tshark:** The terminal-based counterpart of Wireshark, allowing for packet capture and analysis directly from the command line.
- **nmap:** Can scan for unauthorized devices on the network or for suspicious open ports.

Most of these tools require separate installation or sudo privileges, which adds complexity and reduces portability. This script therefore uses only standard tools already present on most Linux systems: it reads network usage directly from `/proc/net/dev` and uses **ss** to monitor commonly targeted ports.

## Script Overview

This Bash script monitors network usage and detects suspicious connections on a Linux system. When executed, it lists all active network interfaces and prompts the user to select one for monitoring. The script then continuously displays real-time incoming and outgoing traffic statistics (in KB/s and total MB) for the chosen interface. At the same time, it checks for active connections on a comprehensive set of commonly targeted ports (including but not limited to 22/SSH, 3389/RDP, 5900/VNC, etc.). If a connection is detected on any of these ports, the script logs an alert (with details such as local/remote IP, port, PID, and process name) to the system log and displays a warning message in red on the terminal. The monitoring continues until manually interrupted by the user (e.g., with CTRL+C). When stopped, the script cleans up all background processes.

### Function Descriptions

- **show_traffic**  
  Monitors the selected network interface and displays the incoming (IN) and outgoing (OUT) traffic in KB/s, along with the total amount of data downloaded and uploaded (in MB). It updates these statistics every second, giving a real-time overview of network activity.

- **check_suspicious**  
  Every 5 seconds, checks for established network connections on a wide list of commonly targeted ports (FTP, SSH, Telnet, SMTP, DNS, HTTP, POP3, NetBIOS, IMAP, SMB, RDP, VNC, MySQL, PostgreSQL, Redis, HTTP-alt, HTTPS-alt, MongoDB, IRC, Flask/dev, and known backdoor ports). If such a connection is found, it logs a detailed alert to the system log (syslog) and prints a warning message (in red) to the terminal with timestamp, IP/port info, PID, and process name.

- **Signal Handling/Cleanup**  
  The script traps interruption signals (like CTRL+C) and ensures all background monitoring processes are terminated cleanly.

## Ports Monitored

The script actively checks for connections on the following ports (you can modify this list in the script as needed):

```
21 22 23 25 53 80 110 139 143 445 3389 5900 3306 5432 6379 8080 8443 27017 6667 5000 12345 31337 2323
```

## Testing the Script

To test the alert mechanism of the monitoring script, you can use a simple Bash script that simulates a suspicious connection on a monitored port (for example, port 22). The script uses `netcat` (`nc`) to open a listening socket on the selected port and then connects to it, triggering the alert in your monitoring tool.

```bash name=test_alert.sh
#!/bin/bash

# Start a netcat listener on port 22 (requires sudo privileges)
sudo nc -lvp 22 &
LISTENER_PID=$!

sleep 2

# Connect to port 22 to simulate a suspicious connection
nc 127.0.0.1 22

# Terminate the listener
kill $LISTENER_PID
```

> **Note:**  
> - Make sure to run this script while your monitoring script is active.
> - You might need to install `netcat` (`nc`) if it's not already available on your system.
> - Change the port number to any in the monitored list to test alerts for those ports.
> - The monitoring script prints alerts in **red** on the terminal and logs them to syslog, including detailed info about the connection and process.

## Usage

1. Run the monitoring script with Bash:
   ```bash
   bash your_monitoring_script.sh
   ```
2. Select the network interface you wish to monitor when prompted.
3. Observe the real-time traffic statistics and watch for any alerts.
4. To stop monitoring, press **CTRL+C** (the script will terminate all background processes cleanly).

