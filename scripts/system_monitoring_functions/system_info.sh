get_system_info(){

    echo -e "${COLOR_TEXT}User: ${COLOR_RESET}$USER"
    echo -e "${COLOR_TEXT}Host: ${COLOR_RESET}$(hostname)"
    echo -e "${COLOR_TEXT}OS: ${COLOR_RESET}$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2- | tr -d '\"')"
    echo -e "${COLOR_TEXT}Kernel: ${COLOR_RESET}$(uname -r)"
    echo -e "${COLOR_TEXT}Uptime: ${COLOR_RESET}$(uptime -p)"
    echo -e "${COLOR_TEXT}Shell: ${COLOR_RESET}$SHELL"
    echo -e "${COLOR_TEXT}Terminal: ${COLOR_RESET}$TERM"
    echo -e "${COLOR_TEXT}CPU: ${COLOR_RESET}$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
    echo -e "${COLOR_TEXT}Memory: ${COLOR_RESET}$(free -h | awk '/^Mem:/ {print $3 " / " $2}')\n"
    }

get_hardware_info(){
    echo -e "${COLOR_TEXT}CPU: ${COLOR_RESET}$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
    echo -e "${COLOR_TEXT}Cores: ${COLOR_RESET}$(nproc)"
    echo -e "${COLOR_TEXT}Architecture: ${COLOR_RESET}$(uname -m)"
    echo -e "${COLOR_TEXT}Memory: ${COLOR_RESET}$(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    echo -e "${COLOR_TEXT}GPU: ${COLOR_RESET}$(lspci | grep -i 'vga\|3d\|2d' | cut -d: -f3 | sed 's/^ //')"
    echo -e "${COLOR_TEXT}Disk(s): ${COLOR_RESET}$(lsblk -d -o NAME,SIZE,MODEL | grep -v '^NAME')\n"
}