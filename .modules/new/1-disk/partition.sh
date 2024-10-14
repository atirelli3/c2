#!/bin/bash

# Get script argument(s)
debug=$1          # Log level (yes or no)
target=$2         # Target disk
espsize=$3        # Bootloader size (MiB)
encrypt=$4        # Encrypt the disk ?
encrypt_key=$5    # Key to encrypt and decrypt disk
encrypt_type=$6   # Encrypt type
encrypt_label=$7  # Label of the encrypt disk
target_part=$8    # Partition label (p for nvme)


# Output rediriction based on debug log level
redir_output=""
[[ "$debug" != "yes" ]] && redir_output="&> /dev/null"

eval "sgdisk -n 0:0:+$espsize -t 0:ef00 -c 0:ESP $target $redir_output"  # EFI partition
eval "sgdisk -n 0:0:0 -t 0:8300 -c 0:rootfs $target $redir_output"       # Root partition
eval "partprobe $target $redir_output"                                   # Inform system of disk changes

# (Optional) Encrypt the root partition
if [ "$encrypt" = "yes" ]; then
    eval "sgdisk -t 2:8309 $target $redir_output"  # Set partition 2 type to LUKS
    eval "partprobe $target $redir_output"         # Inform system of disk changes
    # Encrypt root partition
    eval "echo -n $encrypt_key | cryptsetup --type $encrypt_type -v -y --batch-mode luksFormat ${target_part}2 --key-file=- $redir_output"
    eval "echo -n $encrypt_key | cryptsetup open --perf-no_read_workqueue --perf-no_write_workqueue --persistent ${target_part}2 $encrypt_label --key-file=- $redir_output"
fi