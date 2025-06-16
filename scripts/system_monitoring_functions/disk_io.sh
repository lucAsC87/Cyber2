#!/bin/bash
WAIT_TIME=1 # Time in seconds between 2 /proc/diskstats readings to calculate disk I/O usage

get_disk_io() {
  # Create arrays to store previous disk stats for each device
  declare -A prev_reads prev_reads_merged prev_sectors_read prev_read_time prev_writes prev_writes_merged prev_sectors_written prev_write_time

  # First reading of disk stats from /proc/diskstats
  while read -r major minor dev reads reads_merged sectors_read read_time writes writes_merged sectors_written write_time io_in_progress io_time weighted_io_time; do
    # Only checks storage devices i.e : nvme, sata or hard-drives.
    [[ "$dev" =~ ^(sd|nvme|hd)[a-z0-9]+$ ]] || continue

    # Save the first reading values for this device in arrays
    prev_reads[$dev]=$reads
    prev_reads_merged[$dev]=$reads_merged
    prev_sectors_read[$dev]=$sectors_read
    prev_read_time[$dev]=$read_time
    prev_writes[$dev]=$writes
    prev_writes_merged[$dev]=$writes_merged
    prev_sectors_written[$dev]=$sectors_written
    prev_write_time[$dev]=$write_time
  done < /proc/diskstats

  sleep $WAIT_TIME

  # Second reading of disk stats, to compare with first reading
  while read -r major minor dev reads reads_merged sectors_read read_time writes writes_merged sectors_written write_time io_in_progress io_time weighted_io_time; do
    [[ "$dev" =~ ^(sd|nvme|hd)[a-z0-9]+$ ]] || continue

    # Calculate difference between second and first readings
    read_delta=$((reads - prev_reads[$dev]))
    sectors_read_delta=$((sectors_read - prev_sectors_read[$dev]))
    read_time_delta=$((read_time - prev_read_time[$dev]))
    write_delta=$((writes - prev_writes[$dev]))
    sectors_written_delta=$((sectors_written - prev_sectors_written[$dev]))
    write_time_delta=$((write_time - prev_write_time[$dev]))

    # Each sector usually holds 512 bytes of data
    sector_size=512

    # Calculate bytes read/written per second
    bytes_read_per_sec=$(( (sectors_read_delta * sector_size) / WAIT_TIME ))
    bytes_written_per_sec=$(( (sectors_written_delta * sector_size) / WAIT_TIME ))

    # Output the disk stats for the device
    echo "$dev read_ops=$read_delta write_ops=$write_delta bytes_read/s=$bytes_read_per_sec bytes_written/s=$bytes_written_per_sec read_time_ms=$read_time_delta write_time_ms=$write_time_delta"
  done < /proc/diskstats
}