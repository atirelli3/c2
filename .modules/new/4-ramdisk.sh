# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] Arch 'mkinitcpio' |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Configure Arch Linux ramdisk and    |
# |  |      / /   |             | kernel module(s) w/ mkinitcpio.     |
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

# Define disk partition label (p for nvme):
# This section checks if the target disk is an NVMe device. If true, it appends
# 'p' to the partition label for NVMe-specific naming conventions; otherwise,
# it uses the standard partition naming.
if [[ $target =~ ^/dev/nvme[0-9]+n[0-9]+$ ]]; then
  target_part="${target}p"
else
  target_part="$target"
fi

# ------------------------------------------------------------------------------
#                               MODULE FUNCTION(s)
# ------------------------------------------------------------------------------

# Generate mkinitcpio configuration:
# This function configures the mkinitcpio setup based on encryption and filesystem
# settings. It sets up the necessary hooks for the initramfs generation process.
gen_mkinitcpio() {
  if [ "$encrypt" = "yes" ]; then
    # If encryption is enabled, a keyfile is generated for LUKS encryption
    eval "dd bs=512 count=4 iflag=fullblock if=/dev/random of=/key.bin $2"
    eval "chmod 600 /key.bin $2"  # Restrict access to the keyfile
    # Add the keyfile to the LUKS container
    eval "cryptsetup luksAddKey \"${target_part}2\" /key.bin $2"
    # Add the keyfile to mkinitcpio configuration
    eval "sed -i '/^FILES=/ s/)/ \/key.bin)/' /etc/mkinitcpio.conf $2"
    
    # Configure hooks depending on the filesystem
    if [ "$filesystem" = "btrfs" ]; then
      # Add hooks for encryption and Btrfs
      eval "sed -i '/^HOOKS=/ s/(.*)/(base udev keyboard autodetect microcode keymap consolefont modconf block encrypt btrfs filesystems fsck)/' /etc/mkinitcpio.conf $2"
    else
      # Add hooks for encryption without Btrfs
      eval "sed -i '/^HOOKS=/ s/(.*)/(base udev keyboard autodetect microcode keymap consolefont modconf block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf $2"
    fi
  else
    # If encryption is not enabled, configure hooks without encryption
    if [ "$filesystem" = "btrfs" ]; then
      # Add hooks for Btrfs without encryption
      eval "sed -i '/^HOOKS=/ s/(.*)/(base udev keyboard autodetect microcode keymap consolefont modconf block btrfs filesystems fsck)/' /etc/mkinitcpio.conf $2"
    else
      # Add hooks for non-Btrfs and non-encrypted configurations
      eval "sed -i '/^HOOKS=/ s/(.*)/(base udev keyboard autodetect microcode keymap consolefont modconf block filesystems fsck)/' /etc/mkinitcpio.conf $2"
    fi
  fi
  
  # If the filesystem is Btrfs, add the Btrfs module to mkinitcpio
  if [ "$filesystem" = "btrfs" ]; then
    eval "sed -i '/^MODULES=/ s/)/ btrfs)/' /etc/mkinitcpio.conf $2"
  fi
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
gen_mkinitcpio           ## 1. Configure mkinitcpio.conf with necessary hooks and modules
eval "mkinitcpio -P $2"  ## 2. Generate the initial ramdisk
