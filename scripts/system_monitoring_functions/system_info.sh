# get_system_info displays key system information including user, host, OS, kernel, uptime, shell, terminal, CPU model, and memory usage with color-coded labels.
get_system_info(){

    # Print the current username
    echo -e "${COLOR_TEXT}User: ${COLOR_RESET}$USER"

    # Print the system hostname
    echo -e "${COLOR_TEXT}Host: ${COLOR_RESET}$(hostname)"

    # Print the OS name (tries lsb_release first, falls back to /etc/os-release)
    echo -e "${COLOR_TEXT}OS: ${COLOR_RESET}$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2- | tr -d '\"')"

    # Print the running kernel version
    echo -e "${COLOR_TEXT}Kernel: ${COLOR_RESET}$(uname -r)"

    # Print how long the system has been up
    echo -e "${COLOR_TEXT}Uptime: ${COLOR_RESET}$(uptime -p)"

    # Print the current user's shell
    echo -e "${COLOR_TEXT}Shell: ${COLOR_RESET}$SHELL"

    # Print the terminal type being used
    echo -e "${COLOR_TEXT}Terminal: ${COLOR_RESET}$TERM"

    # Print the CPU model name (first occurrence)
    echo -e "${COLOR_TEXT}CPU: ${COLOR_RESET}$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"

    # Print current memory usage (used / total in human-readable format)
    echo -e "${COLOR_TEXT}Memory: ${COLOR_RESET}$(free -h | awk '/^Mem:/ {print $3 " / " $2}')\n"
}


# get_hardware_info displays detailed hardware information including CPU model, core count, architecture, memory usage, GPU details, and disk device information with color-coded labels.
get_hardware_info(){

    # Print the CPU model name
    echo -e "${COLOR_TEXT}CPU: ${COLOR_RESET}$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"

    # Print the total number of CPU cores
    echo -e "${COLOR_TEXT}Cores: ${COLOR_RESET}$(nproc)"

    # Print the system architecture (e.g. x86_64, arm64)
    echo -e "${COLOR_TEXT}Architecture: ${COLOR_RESET}$(uname -m)"

    # Print current memory usage (used / total in human-readable format)
    echo -e "${COLOR_TEXT}Memory: ${COLOR_RESET}$(free -h | awk '/^Mem:/ {print $3 " / " $2}')"

    # Print GPU info (VGA/3D/2D controllers from lspci)
    echo -e "${COLOR_TEXT}GPU: ${COLOR_RESET}$(lspci | grep -i 'vga\|3d\|2d' | cut -d: -f3 | sed 's/^ //')"

    # Print block devices (disks only) with name, size, and model
    echo -e "${COLOR_TEXT}Disk(s): ${COLOR_RESET}$(lsblk -d -o NAME,SIZE,MODEL | grep -v '^NAME')\n"
}
