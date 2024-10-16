# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] NVIDIA driver     |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Install and configure 'nvidia' gpu  |
# |  |      / /   |             | driver for Arch Linux.              |
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

# ------------------------------------------------------------------------------
#                               MODULE FUNCTION(s)
# ------------------------------------------------------------------------------

setup_nvidia() {
  eval "pacman -S --noconfirm nvidia-open nvidia-open-dkms \
    nvidia-utils opencl-nvidia \
    lib32-nvidia-utils lib32-opencl-nvidia \
    nvidia-settings $2"
  # Add necessary kernel modules and udev rules
  sed -i '/^MODULES=/ s/(\(.*\))/(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub
  bash -c 'echo "ACTION==\"add\", DEVPATH==\"/bus/pci/drivers/nvidia\", RUN+=\"/usr/bin/nvidia-modprobe -c 0 -u\"" > /etc/udev/rules.d/70-nvidia.rules'
  bash -c 'echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" > /etc/modprobe.d/nvidia-power-mgmt.conf'
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
setup_nvidia  ## 1. Install and configure NVIDIA driver(s)
eval "mkinitcpio -P $2"                         ## 2. Generate the initial ramdisk
eval "grub-mkconfig -o /boot/grub/grub.cfg $2"  ## 3. Generate GRUB configuration