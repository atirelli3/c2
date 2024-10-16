# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] Intel driver      |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Install and configure 'intel' gpu   |
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

setup_intel() {
  eval "pacman -S --noconfirm mesa lib32-mesa \
    intel-media-driver libva-intel-driver \
    vulkan-intel lib32-vulkan-intel $2"
  sed -i '/^MODULES=/ s/(\(.*\))/(\1 i915)/' /etc/mkinitcpio.conf  # Add i915 to module(s)
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
setup_nvidia  ## 1. Install and configure Intel driver(s)
eval "mkinitcpio -P $2"                         ## 2. Generate the initial ramdisk
eval "grub-mkconfig -o /boot/grub/grub.cfg $2"  ## 3. Generate GRUB configuration