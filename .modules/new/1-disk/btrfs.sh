#!/bin/bash

# Get script argument(s)
debug=$1                # Log level (yes or no)
root_device=$2          # Root partition
label=$3                # Root label
btrfs_subvols=$4        # Subvolumes mount points
btrfs_subvols_mount=$5  # Mount points (subvolumes)
btrfs_opts=$6           # Mount options
BTRFS_SV_OPTS=$(IFS=,; echo "${btrfs_opts[*]}")  # Btrfs mount options

# Output rediriction based on debug log level
redir_output=""
[[ "$debug" != "yes" ]] && redir_output="&> /dev/null"

eval "mkfs.btrfs -L $label $root_device $redir_output"  # Format as Btrfs
eval "mount $root_device /mnt $redir_output"                  # Mount root

# Create Btrfs subvolumes
eval "btrfs subvolume create /mnt/@ $redir_output"           # System
eval "btrfs subvolume create /mnt/@home $redir_output"       # Home
eval "btrfs subvolume create /mnt/@snapshots $redir_output"  # Snapshots
eval "btrfs subvolume create /mnt/@cache $redir_output"      # Cache
eval "btrfs subvolume create /mnt/@log $redir_output"        # Log
eval "btrfs subvolume create /mnt/@tmp $redir_output"        # Temp
# Create additional subvolumes
for subvol in "${btrfs_subvols[@]}"; do
    eval "btrfs subvolume create /mnt/@$subvol $redir_output"
done
umount /mnt  # Unmount to remount with subvolume options

# Remount with Btrfs subvolumes
eval "mount -o ${BTRFS_SV_OPTS},subvol=@ $root_device /mnt $redir_output"       # System
eval "mkdir -p /mnt/{home,.snapshots,var/cache,var/log,var/tmp} $redir_output"  # Mountpoint(s)
eval "mount -o ${BTRFS_SV_OPTS},subvol=@home $root_device /mnt/home $redir_output"            # Home
eval "mount -o ${BTRFS_SV_OPTS},subvol=@snapshots $root_device /mnt/.snapshots $redir_output" # Snapshots
eval "mount -o ${BTRFS_SV_OPTS},subvol=@cache $root_device /mnt/var/cache $redir_output"      # Cache
eval "mount -o ${BTRFS_SV_OPTS},subvol=@log $root_device /mnt/var/log $redir_output"          # Log
eval "mount -o ${BTRFS_SV_OPTS},subvol=@tmp $root_device /mnt/var/tmp $redir_output"          # Temp
# Mount additional subvolumes
for i in "${!btrfs_subvols[@]}"; do
    mkdir -p /mnt${btrfs_subvols_mount[$i]}
    eval "mount -o ${BTRFS_SV_OPTS},subvol=@${btrfs_subvols[$i]} $root_device /mnt${btrfs_subvols_mount[$i]} $redir_output"
done