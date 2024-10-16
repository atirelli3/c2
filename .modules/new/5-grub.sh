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

# Setup GRUB bootloader:
# This function configures and installs the GRUB bootloader based on system
# configurations such as encryption, secure boot, and OS prober. It backs up the
# current GRUB configuration, modifies settings, and installs GRUB on the EFI
# partition.
setup_grub() {
  # Backup current GRUB configuration
  cp /etc/default/grub /etc/default/grub.backup

  # Update basic GRUB settings
  sed -i "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=30/" /etc/default/grub               # Timeout set to 30s
  sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/" /etc/default/grub            # Use last saved selection
  sed -i "s/^#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=y/" /etc/default/grub       # Save last selection
  sed -i "s/^#GRUB_DISABLE_SUBMENU=.*/GRUB_DISABLE_SUBMENU=y/" /etc/default/grub  # Disable sub-menus

  # Enable os-prober if configured for multi-boot
  if [ "$osprober" = "yes" ]; then
    sed -i "s/^#GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub
  fi

  # Configure GRUB for encrypted disk
  if [ "$encrypt" = "yes" ]; then
    uuid=$(blkid -s UUID -o value ${target_part}2)  # Get UUID of the encrypted partition
    # Update GRUB_CMDLINE_LINUX_DEFAULT for encryption
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptdevice=UUID=${uuid}:${encrypt_label}\"|" /etc/default/grub
    # Preload necessary modules for encrypted disk
    sed -i "s/^GRUB_PRELOAD_MODULES=.*/GRUB_PRELOAD_MODULES=\"part_gpt part_msdos luks\"/" /etc/default/grub
    # Enable GRUB cryptodisk
    sed -i "s/^#GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/" /etc/default/grub
  fi

  # Install GRUB to EFI partition
  if [ "$secureboot" = "yes" && "$checkefi" = "yes" ]; then
    # Install GRUB with Secure Boot support
    eval "grub-install --target=x86_64-efi --efi-directory=/${mountpoint} --bootloader-id=GRUB --modules=\"tpm\" --disable-shim-lock $2"
    eval "grub-mkconfig -o /boot/grub/grub.cfg $2"  # Generate GRUB configuration
    # Secure Boot: Install sbctl and generate keys
    eval "pacman -S --noconfirm sbctl $2"  # Install sbctl for Secure Boot management
    eval "sbctl create-keys $2"            # Create Secure Boot keys
    eval "sbctl enroll-keys -m $2"         # Enroll keys to Secure Boot
    # Sign necessary GRUB and kernel files for Secure Boot
    eval "sbctl sign -s /${mountpoint}/EFI/GRUB/grubx64.efi $2"
    eval "sbctl sign -s /${mountpoint}/grub/x86_64-efi/core.efi $2"
    eval "sbctl sign -s /${mountpoint}/grub/x86_64-efi/grub.efi $2"
    eval "sbctl sign -s /${mountpoint}/vmlinuz-${kernel} $2"
  else
    # Standard GRUB installation without Secure Boot
    eval "grub-install --target=x86_64-efi --efi-directory=/${mountpoint} --bootloader-id=GRUB $2"
    eval "grub-mkconfig -o /boot/grub/grub.cfg $2"  # Generate GRUB configuration
  fi
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
setup_grub  ## 1. Install and configure GRUB bootloader
