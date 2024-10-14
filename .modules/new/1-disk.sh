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
debug=$1  # Log level (yes or no)

source "$2"  # Load configuration file

# Define disk partition label (p for nvme)
[[ $target =~ ^/dev/nvme[0-9]+n[0-9]+$ ]] && target_part="${target}p" || target_part="$target"

./.modules/new/1-disk/wipe.sh "$debug" "$target"  # Wipe the disk
# (optional) Fill the disk w/ random data(s)
if [ "$secure" = "yes" ] && { ./.modules/new/1-disk/secure.sh "$debug" "$target"; }
# Partition the disk
./.modules/new/1-disk/partition.sh "$debug" "$target" "$size" \
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
./.modules/new/1-disk/efi.sh "$debug" "$target_part" "$mountpoint" "$label"