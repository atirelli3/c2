# !/bin/bash

mkfs.vfat -F32 -n $part1_label ${target_part}1 &> /dev/null  # Format the EFI partition
mkdir -p /mnt/$part1_mount
mount ${target_part}1 /mnt/$part1_mount  # Mount EFI partition