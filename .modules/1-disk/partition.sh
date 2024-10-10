# !/bin/bash

sgdisk -n 0:0:+${part1_size} -t 0:ef00 -c 0:ESP $target &> /dev/null  # EFI partition
sgdisk -n 0:0:0 -t 0:8300 -c 0:rootfs $target &> /dev/null            # Root partition
partprobe "$target" &> /dev/null                                      # Inform system of disk changes

# (Optional) Encrypt the root partition
if [ "$encrypt" = "yes" ]; then
    print_info "    - encrypting disk"
    sgdisk -t 2:8309 $target &> /dev/null  # Set partition 2 type to LUKS
    partprobe "$target" &> /dev/null       # Inform system of disk changes
    # Encrypt root partition
    echo -n "$encrypt_key" | cryptsetup --type $encrypt_type -v -y --batch-mode luksFormat ${target_part}2 --key-file=- &> /dev/null
    echo -n "$encrypt_key" | cryptsetup open --perf-no_read_workqueue --perf-no_write_workqueue --persistent ${target_part}2 $encrypt_label --key-file=- &> /dev/null
fi