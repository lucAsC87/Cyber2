# Monitoring 101 Project
==========================

## Overview
The Monitoring 101 project is a Bash-based toolkit designed to help monitor, detect, and report suspicious activity on a Linux system. The toolkit simulates basic Host Intrusion Detection System (HIDS) capabilities using native tools and scripts.

## Folder Structure
The project is organized into the following folders:

* **docs**: contains documentation for the project, including:
	+ Research findings: `research-findings.md`
	+ Toolkit documentation: `toolkit-documentation.md`
	+ User guide: `user-guide.md`
* **scripts**: contains scripts for monitoring system resources, log files, and network traffic, as well as the reporting mechanism:
	+ `monitor-system-resources.sh`
	+ `monitor-log-files.sh`
	+ `monitor-network-traffic.sh`
	+ `reporting-mechanism.sh`
* **tests**: contains test scripts for verifying the functionality of the toolkit:
	+ `test-monitor-system-resources.sh`
	+ `test-monitor-log-files.sh`
	+ `test-monitor-network-traffic.sh`
	+ `test-reporting-mechanism.sh`
* **toolkit**: contains the main scripts for the toolkit:
	+ `monitor.sh`
	+ `report.sh`
	+ `config.sh`
* **demo**: contains scripts and data for demonstrating the toolkit's capabilities:
	+ `demo-script.sh`
	+ `demo-data/`
* **resources**: contains additional resources and references for the project:
	+ `useful-monitoring-commands.md`
	+ `linux-system-monitoring-fundamentals.md`
	+ `classic-sysadmin-viewing-linux-logs.md`
	+ `security-log-management-and-logging-best-practices.md`
	+ `how-to-send-email-in-linux-from-the-command-line.md`
	+ `cron-job-a-comprehensive-guide-for-beginners.md`

## Getting Started
To get started with the project, follow these steps:

1. Clone the repository to your local machine.
2. Review the documentation in the `docs` folder to understand the project's goals and functionality.
3. Explore the scripts in the `scripts` folder to learn more about the toolkit's components.
4. Run the test scripts in the `tests` folder to verify the toolkit's functionality.
5. Use the `demo` folder to demonstrate the toolkit's capabilities.

## Contributing
We welcome contributions to the Monitoring 101 project. If you have ideas for new features or improvements, please submit a pull request or open an issue to discuss your suggestions.

## License
The Monitoring 101 project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
