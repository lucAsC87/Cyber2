## Monitor the Network Traffic on Linux

Linux provides many tools to monitor network traffic, such as:

- **ifconfig:** Shows and configures network interface parameters.
- **ip:** Manages and displays IP addresses, routes, and stats.
- **netstat:** Displays network connections and interface statistics.
- **ss:** Modern replacement for netstat to show sockets and connections.
- **iftop, nload, bmon, vnstat:** Tools for graphical or historical bandwidth monitoring.
- **tcpdump, tshark:** Advanced packet capture and analysis.
- **nmap:** Scans for devices and suspicious open ports.

Most of these require separate installation or sudo privileges, reducing portability. This script uses only standard tools available on most Linux systems.

---

## Script Overview

This Bash script monitors network usage and detects suspicious connections. When executed, it lists all active network interfaces and prompts you to select one for monitoring. Then:

- Displays real-time incoming/outgoing traffic (KB/s) and total traffic (MB).
- Monitors connections on sensitive ports and reports suspicious activity.
- Handles signals and cleanly terminates on exit (CTRL+C).

---

### Main Functions

- **choose_interface**  
  Lists active interfaces and lets the user select one to monitor, validating the input.

- **show_traffic**  
  Shows incoming and outgoing traffic rates (KB/s) on the selected interface and the total downloaded/uploaded data (MB). Alerts if values exceed thresholds (`DEFAULT_DOWNLOAD_THRESHOLD` and `DEFAULT_UPLOAD_THRESHOLD` from `toolkit/config.sh`).  
  Example output:
  ```
  [12:34:56] Download (KB/s): 12.34 | Upload (KB/s): 2.50 | Total Downloaded (MB): 50.12 | Total Uploaded (MB): 5.25
  ```

- **check_suspicious**  
  Checks for established network connections on monitored ports (see below) using `ss`. If connections are found, details (local/remote IP, port, PID, process name) are displayed and an alert is logged via syslog.  
  Example output:
  ```
  Suspicious connections detected:
  Suspicious Connection: Connection to monitored port detected: 127.0.0.1:22 -> 127.0.0.1:54321 (PID 1234, PROC sshd)
  ```  
---

### Monitored Ports

The script checks for connections on these commonly targeted ports (customizable in `MONITOR_PORTS`):

| Port   | Service         |
|--------|-----------------|
| 21     | FTP             |
| 22     | SSH             |
| 23     | Telnet          |
| 25     | SMTP            |
| 53     | DNS             |
| 80     | HTTP            |
| 110    | POP3            |
| 139    | NetBIOS         |
| 143    | IMAP            |
| 445    | SMB             |
| 3389   | RDP             |
| 5900   | VNC             |
| 3306   | MySQL           |
| 5432   | PostgreSQL      |
| 6379   | Redis           |
| 8080   | HTTP-alt        |
| 8443   | HTTPS-alt       |
| 27017  | MongoDB         |
| 6667   | IRC             |
| 5000   | Flask/dev/test  |
| 12345  | NetBus (backdoor)|
| 31337  | Back Orifice    |
| 2323   | Alt Telnet      |
