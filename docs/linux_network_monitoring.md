## Monitor the Network Traffic on Linux

Linux has at its disposal a plethora of tools to monitor network traffic. Among the most commonly used are:

- **ifconfig:** Displays and configures network interface parameters. Useful for checking the status and statistics of network interfaces.
- **ip:** The modern replacement for ifconfig. It manages and displays IP addresses, routes, and more, and can show real-time packet statistics.
- **netstat:** Checks for connections to unknown IP addresses or unusual ports, displaying network connections, routing tables, and interface statistics.
- **iftop:** Monitors real-time bandwidth usage and shows which hosts are sending or receiving the most data.
- **nload:** Provides a simple, real-time graphical representation of incoming and outgoing network traffic on the terminal.
- **bmon:** (Bandwidth Monitor) Shows bandwidth usage on all network interfaces in a graphical, terminal-based interface.
- **vnstat:** Useful for tracking historical network traffic statistics and detecting if unusual amounts of data are being sent to other networks.
- **tcpdump:** Can capture and analyze the traffic to or from a specific port or IP address.
- **tshark:** The terminal-based counterpart of Wireshark, allowing for packet capture and analysis directly from the command line.
- **nmap:** Can scan for unauthorized devices on the network or for suspicious open ports.

The main issue in implementing them in a script is that most of these tools either need to be installed separately or require execution with sudo privileges. Therefore, to avoid complicating the code too much and in order to make it more portable, I opted to use only **netstat** to check the ports most commonly used for malicious purposes, and to read the network usage directly from the `/proc/net/dev` file.

## Script Overview

This Bash script monitors network usage and detects suspicious connections on a Linux system. When executed, it lists all active network interfaces and prompts the user to select one for monitoring. The script then continuously displays real-time incoming and outgoing traffic statistics (in KB/s and total MB) for the chosen interface. At the same time, it checks for active connections on ports 22 (SSH), 3389 (RDP), and 5900 (VNC)—common targets for unauthorized access. If a connection is detected on any of these ports, the script logs an alert and displays a warning message. The monitoring continues until manually interrupted by the user (e.g., with CTRL+C).

### Function Descriptions

- **show_traffic**  
  Monitors the selected network interface and displays the incoming (IN) and outgoing (OUT) traffic in KB/s, along with the total amount of data downloaded and uploaded (in MB). It updates these statistics every second, giving a real-time overview of network activity.

- **check_suspicious**  
  Checks every 5 seconds for established network connections on ports 22, 3389, and 5900, which are commonly used for remote access services (SSH, RDP, VNC) and often targeted by attackers. If such a connection is found, it logs an alert to the system log and prints a warning message to the terminal.  
  
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
> - Change the port number to 3389 or 5900 in both places to test alerts for those ports.

Running this test script should trigger the alert in your monitoring script, confirming that the detection mechanism is working as expected.
