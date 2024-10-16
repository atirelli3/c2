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

# ------------------------------------------------------------------------------
#                              UTILITY FUNCTION(s)
# ------------------------------------------------------------------------------
print_debug() { echo -e "\e[${1}m${2}\e[0m"; }  # Native print/debug output w/ color
print_success() { print_debug "32" "$1"; }      # Green
print_info() { print_debug "36" "$1"; }         # Cyan
print_warning() { print_debug "33" "$1"; }      # Yellow
# Format to stdout the argument '--silent'
debug="yes"
## Set silent to "yes" if $3 == --silent, otherwise set to "no"
[[ "$3" == "--silent" ]] && debug="no"
# Output rediriction based on debug log level
redir_output=""
[[ "$debug" != "yes" ]] && redir_output="&> /dev/null"


# ------------------------------------------------------------------------------
#                                  MAIN SCRIPT
# - Declaration in function for each arg(s) avaible in the script
# ------------------------------------------------------------------------------

# Arg : '--new'
new() {
  # Check prerequisites => root privileges 
  [ "$EUID" -ne 0 ] && { print_warning "Please run as root. Aborting script."; exit 1; }
  # Check prerequisites => system is in UEFI mode
  [[ "$checkefi" = "yes" && ! -d /sys/firmware/efi/efivars ]] && { print_warning "UEFI mode not detected. Aborting script."; exit 1; }

  # 0 - PREPARATION
  print_info "[ ] Preparing the machine for the Arch Linux installation ..."
  ./.modules/new/0-preparation.sh "$1" "$redir_output" 
  print_success "[*] Machine prepared for the Arch Linux installation."

  # 1 - DISK FORMATTING
  print_info "[ ] Formatting ${target} for the Arch Linux installation ..."
  ./.modules/new/1-disk.sh "$1" "$redir_output" 
  print_success "[*] ${target} formatted for the Arch Linux installation."

  # 2 - SYSTEM INSTALLATION
  print_info "[ ] Installing Arch Linux - Base package(s) ..."
  ./.modules/new/2-install.sh "$1" "$redir_output"
  print_success "[*] Arch Linux w/ base package(s) installed."

  # 3 - SYSTEM CONFIGURATION
  print_info "[ ] Configuring Arch Linux ..."
  cp ./.modules/new/3-conf.sh /mnt/tmp/  # Copy the script in /mnt/tmp
  arch-chroot /mnt /bin/bash -c "/tmp/3-conf.sh \"$1\" \"$redir_output\""
  rm -r /mnt/tmp/3-conf.sh  # Remove the script from /tmp
  print_success "[*] Arch Linux configured."

  # 4 - SYSTEM RAMDISK
  print_info "[ ] Configuring ramdisk/kernel (mkinitcpio) ..."
  cp ./.modules/new/4-ramdisk.sh /mnt/tmp/  # Copy the script in /mnt/tmp
  arch-chroot /mnt /bin/bash -c "/tmp/4-ramdisk.sh \"$1\" \"$redir_output\""
  rm -r /mnt/tmp/4-ramdisk.sh  # Remove the script from /tmp
  print_success "[*] Ramdisk/kernel (mkinitcpio) configured."

  # 5 - BOOTLOADER
  print_info "[ ] Configuring bootloader - ${bootloader} ..."
  cp ./.modules/new/5-$bootloader.sh /mnt/tmp/  # Copy the script in /mnt/tmp
  arch-chroot /mnt /bin/bash -c "/tmp/5-$bootloader.sh \"$1\" \"$redir_output\""
  rm -r /mnt/tmp/5-$bootloader.sh  # Remove the script from /tmp
  print_success "[*] Bootloader - ${bootloader} configured."

  # 6 - AUDIO DRIVER
  print_info "[ ] Installing audio driver(s) - ${audio} ..."
  cp ./.modules/new/6-$audio.sh /mnt/tmp/  # Copy the script in /mnt/tmp
  arch-chroot /mnt /bin/bash -c "/tmp/6-$audio.sh \"$1\" \"$redir_output\""
  rm -r /mnt/tmp/6-$audio.sh  # Remove the script from /tmp
  print_success "[+] Audio driver(s) - ${audio} installed."

  # 7 - GRAPHIC DRIVER
  print_info "[ ] Installing graphic driver(s) - ${gpu} ..."
  cp ./.modules/new/7-$gpu.sh /mnt/tmp/  # Copy the script in /mnt/tmp
  arch-chroot /mnt /bin/bash -c "/tmp/7-$gpu.sh \"$1\" \"$redir_output\""  # Corrected 6-$gpu.sh to 7-$gpu.sh
  rm -r /mnt/tmp/7-$gpu.sh  # Remove the script from /tmp
  print_success "[+] Graphic driver(s) - ${gpu} installed."
}

if [[ "$2" = "--new" ]]; then
  new
fi
