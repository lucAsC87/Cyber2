#!/bin/bash
WAIT_TIME=1 # Time in seconds between 2 /proc/stat readings to calculate CPU usage

# Function used to get overall CPU usage
get_cpu_usage() {
  # Read the first snapshot of CPU statistics from /proc/stat
  read cpu prev_user prev_nice prev_system prev_idle prev_iowait prev_irq prev_softirq prev_steal prev_guest prev_guest_nice < /proc/stat

  # Calculate total idle and non-idle times for the first snapshot
  prev_idle_all=$((prev_idle + prev_iowait))
  prev_non_idle=$((prev_user + prev_nice + prev_system + prev_irq + prev_softirq + prev_steal))
  prev_total=$((prev_idle_all + prev_non_idle))

  sleep $WAIT_TIME

  # Read the second snapshot of CPU statistics from /proc/stat
  read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

  # Calculate total idle and non-idle times for the second snapshot
  idle_all=$((idle + iowait))
  non_idle=$((user + nice + system + irq + softirq + steal))
  total=$((idle_all + non_idle))

  # Calculate the differences between the two snapshots
  total_diff=$((total - prev_total))
  idle_diff=$((idle_all - prev_idle_all))

  # Avoid division by zero by setting total_diff to 1 if it's zero
  [[ $total_diff -eq 0 ]] && total_diff=1

  # Calculate and return CPU usage percentages for each category
  echo "cpu_usage=$(awk "BEGIN { printf \"%.2f\", 100 * ($total_diff - $idle_diff) / $total_diff }")"
  echo "user=$(awk "BEGIN { printf \"%.2f\", 100 * ($user - $prev_user) / $total_diff }")"
  echo "nice=$(awk "BEGIN { printf \"%.2f\", 100 * ($nice - $prev_nice) / $total_diff }")"
  echo "system=$(awk "BEGIN { printf \"%.2f\", 100 * ($system - $prev_system) / $total_diff }")"
  echo "idle=$(awk "BEGIN { printf \"%.2f\", 100 * $idle_diff / $total_diff }")"
  echo "iowait=$(awk "BEGIN { printf \"%.2f\", 100 * ($iowait - $prev_iowait) / $total_diff }")"
  echo "irq=$(awk "BEGIN { printf \"%.2f\", 100 * ($irq - $prev_irq) / $total_diff }")"
  echo "softirq=$(awk "BEGIN { printf \"%.2f\", 100 * ($softirq - $prev_softirq) / $total_diff }")"
  echo "steal=$(awk "BEGIN { printf \"%.2f\", 100 * ($steal - $prev_steal) / $total_diff }")"
}

# Function used to get CPU usage per CPU core
get_per_cpu_usage() {
  # Create arrays to save previous CPU stats per core
  declare -A prev_user prev_nice prev_system prev_idle prev_iowait prev_irq prev_softirq prev_steal prev_idle_all prev_total

  # Take the first snapshot: read CPU lines for each core from /proc/stat
  while read -r line; do

    # Process only lines starting with "cpu" followed by a digit (cpu0, cpu1, etc.)
    [[ "$line" =~ ^cpu[0-9]+ ]] || continue

    # Read CPU stats fields for each core into variables
    read cpu u n s i io irq sirq st g gn <<< "$line"
    cpu_id=${cpu}

    # Store first snapshot values in arrays by CPU core
    prev_user[$cpu_id]=$u
    prev_nice[$cpu_id]=$n
    prev_system[$cpu_id]=$s
    prev_idle[$cpu_id]=$i
    prev_iowait[$cpu_id]=$io
    prev_irq[$cpu_id]=$irq
    prev_softirq[$cpu_id]=$sirq
    prev_steal[$cpu_id]=$st

    # Calculate total idle and non-idle times for the first snapshot per core
    idle_all=$((i + io))
    non_idle=$((u + n + s + irq + sirq + st))
    total=$((idle_all + non_idle))

    # Store idle and total times for each CPU core
    prev_idle_all[$cpu_id]=$idle_all
    prev_total[$cpu_id]=$total
  done < /proc/stat

  sleep $WAIT_TIME

  # Take the second snapshot and calculate usage per CPU core
  while read -r line; do
    [[ "$line" =~ ^cpu[0-9]+ ]] || continue
    read cpu user nice system idle iowait irq softirq steal guest guest_nice <<< "$line"
    cpu_id=${cpu}
    
    idle_all=$((idle + iowait))
    non_idle=$((user + nice + system + irq + softirq + steal))
    total=$((idle_all + non_idle))

    # Calculate deltas between snapshots per core
    total_diff=$((total - prev_total[$cpu_id]))
    idle_diff=$((idle_all - prev_idle_all[$cpu_id]))

    # Avoid division by zero by setting total_diff to 1 if it's zero
    [[ $total_diff -eq 0 ]] && total_diff=1

    # Print CPU usage percentages per core
    echo "${cpu_id}_usage=$(awk "BEGIN { printf \"%.2f\", 100 * ($total_diff - $idle_diff) / $total_diff }")"
    echo "${cpu_id}_user=$(awk "BEGIN { printf \"%.2f\", 100 * ($user - ${prev_user[$cpu_id]}) / $total_diff }")"
    echo "${cpu_id}_nice=$(awk "BEGIN { printf \"%.2f\", 100 * ($nice - ${prev_nice[$cpu_id]}) / $total_diff }")"
    echo "${cpu_id}_system=$(awk "BEGIN { printf \"%.2f\", 100 * ($system - ${prev_system[$cpu_id]}) / $total_diff }")"
    echo "${cpu_id}_idle=$(awk "BEGIN { printf \"%.2f\", 100 * $idle_diff / $total_diff }")"
    echo "${cpu_id}_iowait=$(awk "BEGIN { printf \"%.2f\", 100 * ($iowait - ${prev_iowait[$cpu_id]}) / $total_diff }")"
    echo "${cpu_id}_irq=$(awk "BEGIN { printf \"%.2f\", 100 * ($irq - ${prev_irq[$cpu_id]}) / $total_diff }")"
    echo "${cpu_id}_softirq=$(awk "BEGIN { printf \"%.2f\", 100 * ($softirq - ${prev_softirq[$cpu_id]}) / $total_diff }")"
    echo "${cpu_id}_steal=$(awk "BEGIN { printf \"%.2f\", 100 * ($steal - ${prev_steal[$cpu_id]}) / $total_diff }")"
  done < /proc/stat
}

