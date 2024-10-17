# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] Arch installation |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Intall base Linux and Arch Linux    |
# |  |      / /   |             | pkg(s) to build the OS.             |
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

# Gruop pkg(s) by category:
# This section defines package groups that will be installed later. The variables 
# are grouped by their category, such as Linux base packages, base system packages, 
# bootloader-related packages, and extra packages that may depend on the system 
# configuration.
LNX="$kernel $kernel-headers linux-firmware"   ## Base Linux packages
BASE="base base-devel git"                     ## Base system packages
BOOTLOADER="$bootloader efibootmgr"            ## Bootloader packages
EXTRA="sudo"                                   ## Extra packages

# Conditional package addition:
# Based on the user’s configuration, additional packages are conditionally added 
# to the package lists. For example, os-prober is added to the bootloader if 
# multi-boot support is needed, or Btrfs and encryption tools are added if these 
# options are enabled.
[ "$osprober" = "yes" ] && BOOTLOADER+=" os-prober"  # Add os-prober for multi-boot
[ "$filesystem" = "btrfs" ] && EXTRA+=" btrfs-progs" # Add Btrfs utilities
if [ "$encrypt" = "yes" ]; then
  if [ "$filesystem" != "btrfs" ]; then
    EXTRA+=" cryptsetup lvm2"  # Add encryption and LVM tools for non-Btrfs
  else
    EXTRA+=" cryptsetup"       # Only add cryptsetup if using Btrfs
  fi
fi

# ------------------------------------------------------------------------------
#                               MODULE FUNCTION(s)
# ------------------------------------------------------------------------------

# Install base system packages:
# This function runs the 'pacstrap' command to install the Linux kernel, base 
# system packages, bootloader, network utilities, and other extras based on the 
# system configuration. It builds the command dynamically.
install_base_system() {
  eval "pacstrap /mnt $LNX $BASE $cpu-ucode $network $EXTRA $2"  # Install base pkg(s)
}

# Generate the filesystem table (fstab):
# This function runs the 'genfstab' command to generate the fstab file based on 
# the mounted filesystems. It ensures that the system has the correct mount points 
# for booting.
generate_fstab() {
  eval "genfstab -U -p /mnt >> /mnt/etc/fstab $2"  # Generate the fstab file
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
install_base_system  ## 1. Install base packages and kernel
generate_fstab       ## 2. Generate fstab file