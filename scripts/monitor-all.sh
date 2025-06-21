monitor_all(){
    get_average_cpu_stats >/dev/null
    get_disk_io_stats >/dev/null
    get_memory_stats >/dev/null
    get_swap_stats >/dev/null
    get_top_processes_cpu >/dev/null
    get_top_processes_mem >/dev/null
    show_load >/dev/null
}