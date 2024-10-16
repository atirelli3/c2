# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] Disk Format       |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Partition & format the disk where   |
# |  |      / /   |             | the OS will be installed.           |
# |  `----./ /_   |---------------------------------------------------|
#  \______|____|  |    Owner    | a7ir3                               |
#                 |    GitHub   | https://github.com/atirelli3        |
#                 |   Version   | 1.0.0 (beta)                        |
# ---------------------------------------------------------------------

#!/bin/bash
# Script argument(s)
#
# * $1 : Configuration file
# * $2 : stdout log level

# ------------------------------------------------------------------------------
#                                 MODULE HEADER
# ------------------------------------------------------------------------------
source "$1"  # Load configuration file

# Define disk partition label (p for nvme):
# This section checks if the target disk is an NVMe device. If true, it appends
# 'p' to the partition label for NVMe-specific naming conventions; otherwise,
# it uses the standard partition naming.
if [[ $target =~ ^/dev/nvme[0-9]+n[0-9]+$ ]]; then
  target_part="${target}p"
else
  target_part="$target"
fi

# Define root partition target:
# If encryption is enabled, set the root partition to the encrypted device, 
# otherwise, use the second partition as the root device.
if [ "$encrypt" = "yes" ]; then
    root_device="/dev/mapper/${encrypt_label}"
else
    root_device=${target_part}2
fi

# Define which filesystem function call:
# (Btrfs or Ext4 based on filesystem)
function_call="${filesystem}_setup"

# ------------------------------------------------------------------------------
#                               MODULE FUNCTION(s)
# ------------------------------------------------------------------------------
# Wipe the disk:
# This function wipes all existing data from the target disk, clears the partition 
# table, aligns the sectors, and informs the system of the changes using 'partprobe'.
wipe_disk() {
  eval "wipefs -af $target $2"               # Wipe all data on disk
  eval "sgdisk --zap-all --clear $target $2" # Clear partition table
  eval "sgdisk -a 2048 -o $target $2"        # Align sectors to 2048
  eval "partprobe $target $2"                # Inform system of changes
}

# Secure wipe with random data:
# This function performs a secure wipe by filling the disk with random data using 
# 'cryptsetup' and 'dd'. It is only executed if the 'secure' option is enabled.
secure_disk() {
  eval "cryptsetup open --type plain --batch-mode -d /dev/urandom \
        $target target $2"
  eval "dd if=/dev/zero of=/dev/mapper/target bs=1M status=progress \
        oflag=direct $2"
  cryptsetup close target  # Close the temporary 'cryptsetup' target
}

# Partition the disk:
# This function creates an EFI partition and a root partition on the disk. If 
# encryption is enabled, the root partition is formatted as LUKS (Linux Unified 
# Key Setup) for encryption.
partition_disk() {
  eval "sgdisk -n 0:0:+$size -t 0:ef00 -c 0:ESP $target $2"  # Create EFI partition
  eval "sgdisk -n 0:0:0 -t 0:8300 -c 0:rootfs $target $2"    # Create root partition
  eval "partprobe $target $2"                                # Inform system

  # Encrypt the root partition if encryption is enabled
  if [ "$encrypt" = "yes" ]; then
    eval "sgdisk -t 2:8309 $target $2"  # Set partition 2 type to LUKS (Linux Unified Key Setup)
    eval "partprobe $target $2"         # Inform system of changes
    eval "echo -n $encrypt_key | cryptsetup --type $encrypt_type -v -y \
          --batch-mode luksFormat ${target_part}2 --key-file=- $2"
    eval "echo -n $encrypt_key | cryptsetup open --perf-no_read_workqueue \
          --perf-no_write_workqueue --persistent ${target_part}2 \
          $encrypt_label --key-file=- $2"
  fi
}

# Format and mount using Btrfs:
# This function formats the root partition as Btrfs, mounts the root, creates 
# subvolumes (such as @home, @log, etc.), and mounts them. It ensures that the 
# Btrfs structure is set up correctly for system and data separation.
btrfs_setup() {
  BTRFS_SV_OPTS=$(IFS=,; echo "${btrfs_opts[*]}")  # Btrfs mount option(s)

  eval "mkfs.btrfs -L $rootlabel $root_device $2"  # Format as Btrfs
  eval "mount $root_device /mnt $2"                # Mount root

  # Create Btrfs subvolumes
  eval "btrfs subvolume create /mnt/@ $2"           # System subvolume
  eval "btrfs subvolume create /mnt/@home $2"       # Home subvolume
  eval "btrfs subvolume create /mnt/@snapshots $2"  # Snapshots subvolume
  eval "btrfs subvolume create /mnt/@cache $2"      # Cache subvolume
  eval "btrfs subvolume create /mnt/@log $2"        # Log subvolume
  eval "btrfs subvolume create /mnt/@tmp $2"        # Temp subvolume
  # Create additional subvolumes
  for subvol in "${btrfs_subvols[@]}"; do
    eval "btrfs subvolume create /mnt/@$subvol $2"
  done

  umount /mnt  # Unmount to remount with subvolume options

  # Remount with Btrfs subvolumes and mount points
  eval "mount -o ${BTRFS_SV_OPTS},subvol=@ $root_device /mnt $2"  # System subvolume
  eval "mkdir -p /mnt/{home,.snapshots,var/cache,var/log,var/tmp} $2"  # Create mount points
  eval "mount -o ${BTRFS_SV_OPTS},subvol=@home $root_device /mnt/home $2"  # Home subvolume
  eval "mount -o ${BTRFS_SV_OPTS},subvol=@snapshots $root_device /mnt/.snapshots $2"  # Snapshots
  eval "mount -o ${BTRFS_SV_OPTS},subvol=@cache $root_device /mnt/var/cache $2"  # Cache
  eval "mount -o ${BTRFS_SV_OPTS},subvol=@log $root_device /mnt/var/log $2"  # Log
  eval "mount -o ${BTRFS_SV_OPTS},subvol=@tmp $root_device /mnt/var/tmp $2"  # Temp
  # Mount additional subvolumes
  for i in "${!btrfs_subvols[@]}"; do
    mkdir -p /mnt${btrfs_subvols_mount[$i]}
    eval "mount -o ${BTRFS_SV_OPTS},subvol=@${btrfs_subvols[$i]} \
          $root_device /mnt${btrfs_subvols_mount[$i]} $2"
  done
}

# Format and mount using Ext4:
# This function formats the root partition as Ext4 and mounts it at /mnt.
ext4_setup() {
  eval "mkfs.ext4 -L $rootlabel $root_device $2"  # Format as Ext4
  eval "mount $root_device /mnt $2"               # Mount root
}

# Format EFI partition:
# This function formats the EFI partition as FAT32 and mounts it to the specified 
# mount point.
format_efi() {
  eval "mkfs.vfat -F32 -n $label ${target_part}1 $2"  # Format the ESP partition
  mkdir -p /mnt/$mountpoint                           # Create mount point
  mount ${target_part}1 /mnt/$mountpoint              # Mount ESP partition
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
wipe_disk        ## 1. Wipe data in the disk        
[ "$secure" = "yes" ] && secure_disk  ## 2. (optional) Fill the disk w/ random data(s)
partition_disk   ## 3. Partition the disk
$function_call   ## 4. Format root partition
format_efi       ## 5. Format ESP partition
