# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] Preparation       |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Prepare the system to install Arch  |
# |  |      / /   |             | Linux in the machine.               |
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

# Base installer setup:
# This function sets the system's keyboard layout and enables Network Time Protocol 
# (NTP) for time synchronization. Ensures that the correct keyboard layout is used 
# during the installation and that the system's clock is synchronized.
base_setup() {
  loadkeys "$keyboard"                # Set keyboard layout
  eval "timedatectl set-ntp true $2"  # Enable NTP for time sync
}

# Update installer server(s) mirrorlist:
# This function backs up the current mirrorlist, checks if the 'mirrorcountries' 
# variable is defined (which specifies preferred countries for downloading packages), 
# and runs the 'reflector' tool to update the mirrorlist based on the fastest servers.
# It ensures that the system uses the most optimal package servers for installation.
update_mirrorlist() {
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup  # Backup mirrorlist
  # Sanitize 'mirrorcountries' into a string if declared
  reflector_countries=$(declare -p mirrorcountries &>/dev/null && \
                        (IFS=, ; echo "${mirrorcountries[*]}" | \
                        sed 's/ /,/g') || echo "")
  # Run reflector to update mirrorlist
  eval "reflector ${reflector_countries:+--country \"$reflector_countries\"} \
        --protocol https --age 6 --sort rate \
        --save /etc/pacman.d/mirrorlist $2"
  eval "pacman -Syy $2"  # Refresh package manager databases
}

# Configure pacman:
# This function modifies the pacman configuration file to enable color output,
# a more detailed package list during installations, and faster package downloads 
# by enabling parallel downloads. It improves the usability and performance of the 
# package manager.
configure_pacman() {
  sed -i "/etc/pacman.conf" \
    -e "s|^#Color|Color\nILoveCandy|" \
    -e "s|^#VerbosePkgLists|VerbosePkgLists|" \
    -e "s|^#ParallelDownloads.*|ParallelDownloads = 20|"
  eval "pacman -Syy $2"  # Refresh package manager databases
}

# Update and initialize keyrings:
# This function installs the latest Arch Linux keyring to ensure that the system
# trusts the most recent package signing keys. It initializes the keyring and then
# refreshes the package manager databases to make sure the system has the latest
# package information.
update_keyrings() {
  eval "pacman -S --noconfirm archlinux-keyring $2"  # Install updated keyrings
  eval "pacman-key --init $2"  # Initialize newer keyrings
  eval "pacman -Syy $2"        # Refresh package manager databases
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
base_setup         ## 1. Installer base setup
update_mirrorlist  ## 2. Update installer server(s) mirrorlist
configure_pacman   ## 3. Configure pacman for better usability and performance
update_keyrings    ## 4. Install latest Arch Linux keyring(s)
