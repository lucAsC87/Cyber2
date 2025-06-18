#!/bin/bash

# Construct the log file path from the root
LOG_FILE="$CYBER2_ROOT/logs/warnings.log"
mkdir -p "$(dirname "$LOG_FILE")"

get_average_cpu_stats() {

    if ! command -v mpstat &>/dev/null; then
        echo -e "${RED}mpstat not found. Please install the sysstat package.${RESET}"
        return
    fi

    echo -e "${BOLD}${BLUE}=== Real-Time CPU Average Utilization ===${RESET}"

    cpu_stats=$(mpstat 1 1 | awk '/^Average:/ {print}')
    read -r _ _ usr nice sys iowait irq soft steal guest gnice idle <<<"$cpu_stats"
    total=$(awk -v idle="$idle" 'BEGIN { printf "%.2f", 100 - idle }')

    declare -A warnings
    is_over() { awk -v v1="$1" -v v2="$2" 'BEGIN { exit (v1 > v2) ? 0 : 1 }'; }
    is_under() { awk -v v1="$1" -v v2="$2" 'BEGIN { exit (v1 < v2) ? 0 : 1 }'; }

    print_metric() {
        local name=$1 value=$2 threshold=$3 condition=$4 explain=$5
        local color="$GREEN"
        local violated=0

        if [[ "$condition" == "over" ]]; then
            if is_over "$value" "$threshold"; then
                color="$RED"
                violated=1
            fi
        elif [[ "$condition" == "under" ]]; then
            if is_under "$value" "$threshold"; then
                color="$RED"
                violated=1
            fi
        fi

        echo -e "  ${BROWN}${name}:${RESET} ${color}${value}%${RESET}"
        (( violated )) && warnings["$name"]="$explain"
    }

    print_metric "Total Avg" "$total"   85 "over"  "CPU usage is high; may be overloaded"
    print_metric "usr"       "$usr"     70 "over"  "Too much user-space processing"
    print_metric "nice"      "$nice"    20 "over"  "Too many low-priority background jobs"
    print_metric "sys"       "$sys"     30 "over"  "Excessive system/kernel activity"
    print_metric "iowait"    "$iowait"  10 "over"  "Waiting too long on disk or I/O"
    print_metric "irq"       "$irq"     10 "over"  "Too many hardware interrupts"
    print_metric "soft"      "$soft"    10 "over"  "Too many software interrupts"
    print_metric "steal"     "$steal"   10 "over"  "Other VMs are stealing CPU time"
    print_metric "guest"     "$guest"   50 "over"  "Unusual guest CPU usage"
    print_metric "gnice"     "$gnice"   20 "over"  "Unusual guest nice usage"
    print_metric "idle"      "$idle"    20 "under" "Low idle means CPU is heavily loaded"

    if (( ${#warnings[@]} > 0 )); then
        echo -e "\n${RED}${BOLD}Warnings:${RESET}"
        for key in "${!warnings[@]}"; do
            echo -e "${RED}- $key: ${warnings[$key]}${RESET}"
            echo -e "CPU WARNING$: $key: ${warnings[$key]} ($(date '+%F %T'))" >> "$LOG_FILE"
        done
    fi
}

get_all_cpu_stats() {
    if ! command -v mpstat &>/dev/null; then
        echo -e "${RED}mpstat not found. Please install the sysstat package.${RESET}"
        return
    fi

    echo -e "${BLUE}${BOLD}=== Real-Time CPU Utilization Per Core ===${RESET}"
    warnings=()
    is_over() { awk -v v1="$1" -v v2="$2" 'BEGIN { exit (v1 > v2) ? 0 : 1 }'; }

    mpstat -P ALL 1 1 | awk '
        /^Average:/ && $2 != "all" && $2 != "CPU" {
            print $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
        }
    ' | while read -r cpu_id usr nice sys iowait irq soft steal guest gnice idle; do
        total=$(awk -v i="$idle" 'BEGIN { printf "%.2f", 100 - i }')
        color="$GREEN"
        if is_over "$total" 85; then
            color="$RED"
            warning="Core $cpu_id high usage (${total}%)"
            warnings+=("$warning")
            echo "$(date '+%F %T') - Core $cpu_id: $warning" >> "$LOG_FILE"
        fi

        echo -en "${BROWN}Core ${cpu_id}:${RESET} ${BOLD}Total: ${color}${total}%%${RESET} ${BROWN}|${RESET} "
        echo -en "${BROWN}usr:${RESET} ${color}${usr}%% "
        echo -en "${BROWN}nice:${RESET} ${color}${nice}%% "
        echo -en "${BROWN}sys:${RESET} ${color}${sys}%% "
        echo -en "${BROWN}iowait:${RESET} ${color}${iowait}%% "
        echo -en "${BROWN}irq:${RESET} ${color}${irq}%% "
        echo -en "${BROWN}soft:${RESET} ${color}${soft}%% "
        echo -en "${BROWN}steal:${RESET} ${color}${steal}%% "
        echo -en "${BROWN}guest:${RESET} ${color}${guest}%% "
        echo -en "${BROWN}gnice:${RESET} ${color}${gnice}%% "
        echo -e "${BROWN}idle:${RESET} ${color}${idle}%%${RESET}"
    done

    if (( ${#warnings[@]} > 0 )); then
        echo -e "\n${RED}${BOLD}Warnings:${RESET}"
        for w in "${warnings[@]}"; do
            echo -e "${RED}- $w${RESET}"
        done
    fi
}