get_system_info(){

    echo -e "${BROWN}User: ${RESET}$USER"
    echo -e "${BROWN}Host: ${RESET}$(hostname)"
    echo -e "${BROWN}OS: ${RESET}$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2- | tr -d '\"')"
    echo -e "${BROWN}Kernel: ${RESET}$(uname -r)"
    echo -e "${BROWN}Uptime: ${RESET}$(uptime -p)"
    echo -e "${BROWN}Shell: ${RESET}$SHELL"
    echo -e "${BROWN}Terminal: ${RESET}$TERM"
    echo -e "${BROWN}CPU: ${RESET}$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
    echo -e "${BROWN}Memory: ${RESET}$(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    }

get_hardware_info(){
    echo -e "${BROWN}CPU: ${RESET}$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
    echo -e "${BROWN}Cores: ${RESET}$(nproc)"
    echo -e "${BROWN}Architecture: ${RESET}$(uname -m)"
    echo -e "${BROWN}Memory: ${RESET}$(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    echo -e "${BROWN}GPU: ${RESET}$(lspci | grep -i 'vga\|3d\|2d' | cut -d: -f3 | sed 's/^ //')"
    echo -e "${BROWN}Disk(s): ${RESET}$(lsblk -d -o NAME,SIZE,MODEL | grep -v '^NAME')"
}