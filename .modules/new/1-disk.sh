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

# Get script argument(s)
debug=$1            # Log level (yes or no)
target=$2           # Target disk
secure=$3           # Fill disk w/ random data(s) ?
rootlabel=$4        # Root partition label
espsize=$5          # Bootloader size (MiB)
espmountpoint=$6    # Bootloader mountpoint
esplabel=$7         # ESP partition label
encrypt=$8          # Encrypt the disk ?
encrypt_key=$9      # Key to encrypt and decrypt disk
encrypt_type=${10}  # Encrypt type
encrypt_label=${11} # Label of the encrypt disk

# Define disk partition label (p for nvme)
[[ $target =~ ^/dev/nvme[0-9]+n[0-9]+$ ]] && target_part="${target}p" || target_part="$target"


shift 11  # Shift the first 11 arguments, so we can access the remaining ones (btrfs)
# If btrfs-specific arguments are passed, they will be accessible in $@
if [ "$filesystem" = "btrfs" ]; then
    btrfs_subvols=$1
    btrfs_subvols_mount=$2
    btrfs_opts=$3
fi

./.modules/new/1-disk/wipe.sh "$debug" "$target"  # Wipe the disk
# (optional) Fill the disk w/ random data(s)
if [ "$secure" = "yes" ] && { ./.modules/new/1-disk/secure.sh "$debug" "$target"; }
# Partition the disk
./.modules/new/1-disk/partition.sh "$debug" "$target" "$espsize" \
"$encrypt" "$encrypt_key" "$encrypt_type" "$encrypt_label" \
"$target_part"
if [ "$encrypt" = "yes" ]; then
    root_device="/dev/mapper/${encrypt_label}"  # Set root to encrypted partition
else
    root_device=${target_part}2                 # Set root to non-encrypted partition
fi

if [ "$filesystem" = "btrfs" ]; then
    ./.modules/new/1-disk/${filesystem}.sh "$debug" "$root_device" "$rootlabel" \
    "$btrfs_subvols" "$btrfs_subvols_mount" "$btrfs_opts"
else
    ./.modules/new/1-disk/${filesystem}.sh "$debug" "$root_device" "$rootlabel"
fi
./.modules/new/1-disk/efi.sh "$debug" "$target_part" "$mountpoint" "$esplabel"