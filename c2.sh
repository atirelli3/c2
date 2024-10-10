# !/bin/bash

source "$1"  # Load configuration file

# Chek if the "c2" option is '--new'
if [[ "$2" != "--new" ]]; then
    # Check prerequisites => root privileges 
    [ "$EUID" -ne 0 ] && { echo "Please run as root. Aborting script."; exit 1; }
     # Check prerequisites => system is in UEFI mode
    [ -d /sys/firmware/efi/efivars ] || { echo "UEFI mode not detected. Aborting script."; exit 1; }
fi

# Utility functions
print_debug() { echo -e "\e[${1}m${2}\e[0m"; }
print_success() { print_debug "32" "$1"; }  # Green
print_info() { print_debug "36" "$1"; }     # Cyan
print_warning() { print_debug "33" "$1";}   # Yellow

# TODO: pass the params get from the config file (for all modules *.sh)

# 0 - Preparation
print_info "[ ] Preparing the machine for the Arch Linux installation ..."
./.modules/0-preparation.sh
print_success "[*] Machine prepared for the Arch Linux installation."

# 1 - Disk formatting
print_info "[ ] Formatting ${target} for the Arch Linux installation ..."
./.modules/1-disk/wipe.sh
if [ "$target_secure" = "yes" ] && { ./.modules/1-disk/secure.sh; }
./.modules/1-disk/partition.sh
if [ "$encrypt" = "yes" ]; then
    root_device="/dev/mapper/${encrypt_label}"  # Set root to encrypted partition
else
    root_device=${target_part}2                 # Set root to non-encrypted partition
fi
./.modules/1-disk/${part2_fs}.sh
./.modules/1-disk/efi.sh
print_success "[*] ${target} formatted for the Arch Linux installation."

# 2 - Install Arch Linux
print_info "[ ] Installing Arch Linux - Base package(s) ..."
./.modules/2-install.sh
print_success "[*] Arch Linux w/ base package(s) installed."