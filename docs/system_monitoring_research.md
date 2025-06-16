# System monitoring for debian linux distributions.

System monitoring is an essential aspect of maintaining the performance, stability, and security of any Linux system. On Debian-based distributions, such as Debian itself, Ubuntu, and Kali Linux, system monitoring involves observing resource usage, tracking system processes, analyzing logs, and ensuring that services and hardware components function as expected.

## 1. Default System Monitoring Commands in Debian

Debian Linux distributions come with a set of essential command-line utilities pre-installed, which provide comprehensive system monitoring capabilities covering CPU, memory, disk I/O, network, and process status. These tools are lightweight, reliable, and do not require extra package installation for basic system monitoring tasks.

### Common Default System Monitoring Commands

| Command    | Description                                                                                      | Notes                                  |
|------------|------------------------------------------------------------------------------------------------|---------------------------------------|
| `top`      | Interactive process viewer showing real-time CPU, memory, and process statistics.               | Overview of system load and processes |
| `vmstat`   | Displays virtual memory, CPU, paging, and process information in a tabular format.              | Useful for spotting bottlenecks       |
| `ps`       | Lists running processes and their CPU/memory usage snapshots.                                   | Good for scripting and snapshot views |
| `uptime`   | Shows system uptime and load averages over 1, 5, and 15 minutes.                                | Indicates overall system load         |
| `free`     | Reports memory usage: total, used, free, shared, buffer/cache, and swap memory.                 |                                       |
| `df`       | Shows disk space usage of mounted filesystems.                                                  |                                       |
| `du`       | Estimates file and directory disk space usage.                                                  |                                       |
| `iostat`   | Reports CPU and disk I/O statistics.                                                           | Requires `sysstat` package            |
| `sar`      | Collects, reports, and saves system activity information.                                       | Requires `sysstat` package            |
| `netstat`  | Displays network connections, routing tables, and interface stats.                             | Older tool, but usually installed     |
| `ss`       | Displays detailed socket statistics; modern alternative to `netstat`.                         |                                       |
| `dmesg`    | Shows kernel ring buffer messages. Useful for hardware and driver diagnostics.                  |                                       |
| `pidstat`  | Reports per-process statistics like CPU usage, I/O, and memory.                                | Requires `sysstat` package            |
| `watch`    | Executes a program periodically, showing output live.                                          | Useful for monitoring commands        |

#### Filesystem and Kernel Interface Files
All these commands rely heavily on the virtual filesystems `/proc` and `/sys` to gather system state information. While some tools like `iostat`, `sar`, and `pidstat` may need the `sysstat` package installed, the core utilities like `top`, `vmstat`, `ps`, `free`, `df`, and `netstat` are almost always available by default on Debian systems and serve as the fundamental building blocks of system monitoring.

| Filesystem/Path | Description                                                           |
|-----------------|-----------------------------------------------------------------------|
| `/proc`         | Virtual filesystem with live kernel and system stats (`/proc/stat`, `/proc/meminfo`, `/proc/diskstats`, `/proc/net/dev`) |
| `/sys`          | Hardware and kernel subsystem information and device stats           |


## 2. Hardware monitoring.

Hardware monitoring on Debian-based Linux systems is crucial for maintaining system health, diagnosing performance bottlenecks, and preventing hardware failures. It involves tracking metrics such as CPU temperature, fan speeds, voltages, disk health, and battery status. Debian and its derivatives, like Ubuntu and Kali Linux, provide a variety of tools and interfaces for accessing real-time hardware information through the /proc and /sys filesystems, as well as through sensor libraries and utilities.


### 2.1. CPU monitoring.

Monitoring CPU usage is essential for spotting abnormal system behavior that may indicate malware. Malware often consumes high CPU resources to perform unauthorized activities like cryptomining or spying. By tracking CPU load and identifying unexpected spikes or sustained usage, administrators can detect and investigate suspicious processes early, helping prevent system slowdowns and security breaches.

#### Understanding `/proc/stat`

The `/proc/stat` file contains kernel and CPU statistics accumulated since the system booted. The values are cumulative and measured in *jiffies* (units of time, typically 1/100 second). Each field represents how much time the CPU has spent in a given state.

##### Example output:

```bash
┌──(thinkpad@Becode)-[~]
└─$ cat /proc/stat                                                                                                 
cpu  288411 15 102915 4955263 3049 0 9069 0 0 0
cpu0 68549 2 23639 1253149 582 0 2291 0 0 0
cpu1 71098 2 25123 1243757 718 0 4866 0 0 0
cpu2 72146 9 26177 1245724 719 0 859 0 0 0
cpu3 76616 1 27975 1212632 1028 0 1052 0 0 0
intr 19315831 35 15641 0 0 0 0 0 0 0 0 0 0 47972 0 0 13652 0 0 5 515156 140703 55072 27 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 24328817
btime 1750071220
processes 116780
procs_running 1
procs_blocked 0
softirq 8816861 7 3686105 222 464377 60465 0 15611 3225571 0 1364503
```


##### Field Breakdown:

| Field        | Description                                                                                  | Value      |
|--------------|----------------------------------------------------------------------------------------------|------------|
| `cpu`        | Label indicating aggregated stats for all CPUs.                                             | cpu        |
| `user`       | Time spent executing user-level applications (non-kernel code), in ticks.                    | 288411     |
| `nice`       | Time spent running user-level applications with low priority (`nice`), in ticks.             | 15         |
| `system`     | Time spent executing kernel-level (system) processes, in ticks.                              | 102915     |
| `idle`       | Time spent doing nothing (idle), in ticks.                                                  | 4955263    |
| `iowait`     | Time CPU was idle waiting for I/O operations, in ticks.                                     | 3049       |
| `irq`        | Time spent servicing hardware interrupts, in ticks.                                         | 0          |
| `softirq`    | Time spent servicing software interrupts, in ticks.                                         | 9069       |
| `steal`      | Time stolen by hypervisor for other VMs, in ticks.                                          | 0          |
| `guest`      | Time spent running a guest OS (virtual CPU), in ticks.                                      | 0          |
| `guest_nice` | Time running low-priority guest tasks, in ticks.                                            | 0          |

---

##### Other `/proc/stat` Fields

| Field           | Description                                                                                   | Value        |
|-----------------|-----------------------------------------------------------------------------------------------|--------------|
| `intr`          | Total number of interrupts since boot (followed by IRQ-specific counts, omitted here)         | 19315831     |
| `softirq`       | Total number of softirqs handled since boot                                                   | 8816861      |
| `ctxt`          | Total number of context switches performed by the kernel                                      | 24328817     |
| `btime`         | System boot time (Unix timestamp)                                                             | 1750071220   |
| `processes`     | Number of processes created since boot                                                        | 116780       |
| `procs_running` | Number of processes currently running                                                         | 1            |
| `procs_blocked` | Number of processes currently blocked (usually waiting on I/O)  

---

#### Concept: Monitoring CPU Usage from `/proc/stat`

To calculate CPU usage accurately, we must:
1. Take two snapshots of the CPU time fields (from `/proc/stat`) spaced a short interval apart.
2. Subtract the first snapshot from the second to get the change (delta) in each CPU time category.
3. Compute the total elapsed time, and determine how much of that was spent on active vs idle tasks.

This approach allows for precise tracking of CPU usage, broken down by mode (user, system, idle, etc.), and is exactly how tools like `top`, `vmstat`, and `htop` derive their metrics behind the scenes.

### 2.2. Disk I/O monitoring.
Monitoring disk I/O activity is important because it helps us understand how our system reads from and writes to storage devices, which affects overall performance and responsiveness. High or unusual disk I/O can indicate bottlenecks that slow down applications or the entire system.

From a security perspective, monitoring disk I/O can help detect suspicious behavior, such as unexpected spikes in read/write operations caused by malware, ransomware encrypting files, or unauthorized data exfiltration. Early detection of abnormal disk activity enables timely investigation and response to potential threats, helping protect data integrity and system stability.

#### Understanding `/proc/diskstats`

The `/proc/diskstats` file provides raw disk I/O statistics accumulated since system boot, tracked per device.

##### Example output:

```bash
┌──(thinkpad@Becode)-[~]
└─$ cat /proc/diskstats                                                                                            
   8       0 sda 29760 11108 2472894 13677 31105 32585 3945240 52119 0 29204 79945 0 0 0 0 7703 14148
   8       1 sda1 29598 11108 2467274 13631 31104 32585 3945240 52118 0 30504 65749 0 0 0 0 0 0
   8       2 sda2 2 0 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   8       5 sda5 66 0 2928 18 0 0 0 0 0 8 18 0 0 0 0 0 0
  11       0 sr0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```


##### Field Breakdown:
| Field                  | Description                                        | sda      |
|------------------------|--------------------------------------------------|----------|
| Major number           | Device major number                               | 8        |
| Minor number           | Device minor number                               | 0        |
| Device name            | Name of the device                                | sda      |
| Reads completed        | Number of reads completed successfully (count)   | 29760    |
| Reads merged           | Number of reads merged (count)                    | 11108    |
| Sectors read           | Number of sectors read (512 bytes each)           | 2472894  |
| Time spent reading     | Time spent reading (milliseconds)                 | 13677    |
| Writes completed       | Number of writes completed successfully (count)  | 31105    |
| Writes merged          | Number of writes merged (count)                    | 32585    |
| Sectors written        | Number of sectors written (512 bytes each)         | 3945240  |
| Time spent writing     | Time spent writing (milliseconds)                 | 52119    |
| I/Os in progress       | Number of I/O operations currently in progress    | 0        |
| Time spent doing I/Os  | Time spent doing I/O (milliseconds)               | 29204    |
| Weighted I/O time      | Weighted time spent doing I/O (milliseconds)      | 79945    |
| Discards completed     | Number of discard operations completed (count)    | 0        |
| Discards merged        | Number of discard operations merged (count)       | 0        |
| Sectors discarded      | Number of sectors discarded (512 bytes each)       | 0        |
| Time spent discarding  | Time spent discarding (milliseconds)              | 0        |
| Flush requests         | Number of flush requests completed (count)        | 7703     |
| Time spent flushing    | Time spent flushing (milliseconds)                | 14148    |

### Concecpt: monitoring disk I/O usage from `/proc/diskstats`
To measure disk I/O activity accurately, we follow a similar method:
1. Take two snapshots of the relevant disk statistics from /proc/diskstats, spaced a short interval apart (e.g., 1 second).
2. Calculate the difference (delta) between the two snapshots for fields like sectors read/written and time spent on I/O.
3. Convert these deltas into meaningful metrics such as read/write operations per second, bytes per second (using sector size, usually 512 bytes), and I/O time in milliseconds.

This technique enables precise tracking of how much data is being read from or written to each device, how busy each disk is, and how long I/O operations are taking. It's the foundation for many performance monitoring tools like iostat, dstat, and collectl.

### 2.3. Swap monitoring.

### 2.4. Process monitoring