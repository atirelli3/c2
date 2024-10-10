# !/bin/bash

mkfs.btrfs -L $part2_label $root_device &> /dev/null  # Format as Btrfs
mount $root_device /mnt                               # Mount root

# Create Btrfs subvolumes
btrfs subvolume create /mnt/@ &> /dev/null           # System
btrfs subvolume create /mnt/@home &> /dev/null       # Home
btrfs subvolume create /mnt/@snapshots &> /dev/null  # Snapshots
btrfs subvolume create /mnt/@cache &> /dev/null      # Cache
btrfs subvolume create /mnt/@log &> /dev/null        # Log
btrfs subvolume create /mnt/@tmp &> /dev/null        # Temp
# Create additional subvolumes
for subvol in "${btrfs_subvols[@]}"; do
    btrfs subvolume create /mnt/@$subvol &> /dev/null
done
umount /mnt  # Unmount to remount with subvolume options

# Remount with Btrfs subvolumes
mount -o ${BTRFS_SV_OPTS},subvol=@ $root_device /mnt &> /dev/null         # System
mkdir -p /mnt/{home,.snapshots,var/cache,var/log,var/tmp} &> /dev/null    # Mountpoint(s)
mount -o ${BTRFS_SV_OPTS},subvol=@home $root_device /mnt/home             # Home
mount -o ${BTRFS_SV_OPTS},subvol=@snapshots $root_device /mnt/.snapshots  # Snapshots
mount -o ${BTRFS_SV_OPTS},subvol=@cache $root_device /mnt/var/cache       # Cache
mount -o ${BTRFS_SV_OPTS},subvol=@log $root_device /mnt/var/log           # Log
mount -o ${BTRFS_SV_OPTS},subvol=@tmp $root_device /mnt/var/tmp           # Temp
# Mount additional subvolumes
for i in "${!btrfs_subvols[@]}"; do
    mkdir -p /mnt${btrfs_subvols_mount[$i]}
    mount -o ${BTRFS_SV_OPTS},subvol=@${btrfs_subvols[$i]} $root_device /mnt${btrfs_subvols_mount[$i]}
done