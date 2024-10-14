#!/bin/bash

# Get script argument(s)
debug=$1        # Log level (yes or no)
target_part=$2  # Partition label (p for nvme)
mountpoint=$3   # Mountpoit for ESP partition
label=$4        # ESP partition label

# Output rediriction based on debug log level
redir_output=""
[[ "$debug" != "yes" ]] && redir_output="&> /dev/null"

eval "mkfs.vfat -F32 -n $label ${target_part}1 $redir_output"  # Format the ESP partition
mkdir -p /mnt/$mountpoint               # Create mountpoint
mount ${target_part}1 /mnt/$mountpoint  # Mount ESP partition