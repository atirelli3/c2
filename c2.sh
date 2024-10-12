# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - General Script             |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Main script that operate based on   |
# |  |      / /   |             | which option(s) are passed as args. |
# |  `----./ /_   |---------------------------------------------------|
#  \______|____|  |    Owner    | a7ir3                               |
#                 |    GitHub   | https://github.com/atirelli3        |
#                 |   Version   | 1.0.0 (beta)                        |
# ---------------------------------------------------------------------

#!/bin/bash

source "$1"  # Load configuration file

# Utility functions
print_debug() { echo -e "\e[${1}m${2}\e[0m"; }  # Native print/debug output w/ color
print_success() { print_debug "32" "$1"; }      # Green
print_info() { print_debug "36" "$1"; }         # Cyan
print_warning() { print_debug "33" "$1"; }      # Yellow

# Set silent to "yes" if $3 == --silent, otherwise set to "no"
debug="yes"
[[ "$3" == "--silent" ]] && debug="no"

# Check if the "c2" option is '--new'
if [[ "$2" = "--new" ]]; then
    # Check prerequisites => root privileges 
    [ "$EUID" -ne 0 ] && { print_warning "Please run as root. Aborting script."; exit 1; }
    # Check prerequisites => system is in UEFI mode
    [[ "$checkefi" = "yes" && ! -d /sys/firmware/efi/efivars ]] && { print_warning "UEFI mode not detected. Aborting script."; exit 1; }

    # 0 - Preparation
    print_info "[ ] Preparing the machine for the Arch Linux installation ..."
    ./.modules/new/0-preparation.sh "$debug" "$keyboard" "$mirrorcountries"
    print_success "[*] Machine prepared for the Arch Linux installation."
fi



# 1 - Disk formatting
    # print_info "[ ] Formatting ${target} for the Arch Linux installation ..."
    # ./.modules/new/1-disk.sh
    # print_success "[*] ${target} formatted for the Arch Linux installation."

    # # 2 - Install Arch Linux
    # print_info "[ ] Installing Arch Linux - Base package(s) ..."
    # ./.modules/new/2-install.sh
    # print_success "[*] Arch Linux w/ base package(s) installed."