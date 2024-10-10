# !/bin/bash

wipefs -af "$target" &> /dev/null                # Wipe all data
sgdisk --zap-all --clear "$target" &> /dev/null  # Clear partition table
sgdisk -a 2048 -o "$target" &> /dev/null         # Align sectors to 2048
partprobe "$target" &> /dev/null                 # Inform system of disk changes