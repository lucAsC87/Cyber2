
# Log Monitoring Script Documentation

## Overview
This script provides automated monitoring and analysis of system log files. It processes both APT history logs and system error logs to generate easy-to-read reports.

## Features
- Monitors APT history logs (/var/log/apt/history.log)
- Tracks system errors using journalctl
- Generates detailed reports with statistics
- Creates automatic backups of log files
- Outputs organized reports in a dedicated directory

## Usage
```bash
./monitor-log-files.sh
```

## Output
The script creates a `log` directory containing:
- history_report.txt: Analysis of APT history logs
- system_error_report.txt: Recent system errors
- history.backup: Backup of the APT history log
- system_errors.backup: Backup of system error logs

## Reports Include
- Total number of log entries
- Count of error entries
- Most recent error messages
- Latest system errors

## Requirements
- Root/sudo access for journalctl commands
- Read access to /var/log/apt/history.log
- Bash shell environment

## Error Handling
The script checks for the existence of required log files and will exit with an error message if they are not found.
