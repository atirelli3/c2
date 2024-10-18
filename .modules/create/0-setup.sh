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
ymlfile="$1" # Configuration file
stdout="$2"  # Standard output

# System
system_keyboard="$(yq '.system.keyboard' "$ymlfile")" # Keyboard layout

# Mirrorlist
mirrorlist_reflector_enable="$(yq '.mirrorlist.reflector.enable' "$ymlfile")" # Enable reflector
mirrorlist_reflector_country="$(yq \
  '.mirrorlist.reflector.country[]' "$ymlfile" | paste -sd ",")"              # Reflector country

# Pacman
pacman_bar="$(yq '.pacman.bar' "$ymlfile")"         # Fancy progress bar
pacman_color="$(yq '.pacman.color' "$ymlfile")"     # Color output
pacman_verbose="$(yq '.pacman.verbose' "$ymlfile")" # Verbose package list
pacman_parallel_download_enable="$(yq \
  '.pacman.parallel_download.enable' "$ymlfile")"   # Parallel download
pacman_parallel_download_n="$(yq \
  '.pacman.parallel_download.number' "$ymlfile")"   # Number of parallel download(s) [MAX]


# ------------------------------------------------------------------------------
#                               MODULE FUNCTION(s)
# ------------------------------------------------------------------------------

# Base setup
#
# This function sets up the basic system configurations required for the Arch 
# Linux installation. It loads the specified keyboard layout and enables Network 
# Time Protocol (NTP) for time synchronization. These steps ensure that the 
# correct keyboard layout is used during the installation and that the system 
# clock is properly synchronized with network time servers.
base_setup() {
  loadkeys "$system_keyboard"        # Load keyboard layout
  eval "timedatectl set-ntp true $2" # Enable NTP for time sync
}

# Update mirrorlist
#
# This function updates the Arch Linux pacman mirrorlist to ensure that the 
# system uses the most optimal and fastest servers for downloading packages. 
# It first creates a backup of the current mirrorlist. Then, it runs the 
# `reflector` command to update the mirrorlist based on the countries specified 
# in the configuration (YAML) file, sorting servers by rate and using the HTTPS 
# protocol. Finally, it refreshes the pacman database to apply the new mirrorlist.
update_mirrorlist() {
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup  # Backup mirrorlist
  eval "reflector --country ${mirrorlist_reflector_country} \
        --protocol https --age 6 --sort rate \
        --save /etc/pacman.d/mirrorlist $2" # Run reflector to update mirrorlist
  eval "pacman -Syy $2" # Refresh pacman database(s)
}

# Configure pacman
#
# This function modifies the pacman configuration file based on the settings 
# read from the YAML configuration file. It enables various pacman features 
# such as color output, a fancy progress bar, verbose package list, and parallel 
# downloads. After configuring these options, it refreshes the pacman databases 
# by running `pacman -Syy`.
configure_pacman() {
  pacman_conf="/etc/pacman.conf" # Pacman configuration file
  
  [[ "$pacman_color" == "yes" ]] && sed -i "$pacman_conf" -e "s|^#Color|Color|"   # Enable Color output
  [[ "$pacman_bar" == "yes" ]] && sed -i "$pacman_conf" -e "/^Color/a ILoveCandy" # Enable fancy progress bar

  [[ "$pacman_verbose" == "yes" ]] && sed -i "$pacman_conf" \
    -e "s|^#VerbosePkgLists|VerbosePkgLists|"                                     # Enable verbose package list

  [[ "$pacman_parallel_download_enable" == "yes" ]] && sed -i "$pacman_conf" \
    -e "s|^#ParallelDownloads.*|ParallelDownloads = $pacman_parallel_download_n|" # Enable parallel download

  eval "pacman -Syy $2" # Refresh pacman database(s)
}

# Update keyring(s)
#
# This function updates and initializes the Arch Linux keyrings, ensuring that 
# the system has the most recent package signing keys. It installs the latest 
# Arch Linux keyring package, initializes the keyring, and refreshes the pacman 
# databases to ensure the system is up-to-date with the most recent package 
# signing keys.
update_keyrings() {
  eval "pacman -S --noconfirm archlinux-keyring $2"  # Install updated keyrings
  eval "pacman-key --init $2"  # Initialize newer keyrings
  eval "pacman -Syy $2" # Refresh pacman database(s)
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
base_setup       ## 1. Setup installer
[[ "$mirrorlist_reflector_enable" == "yes" ]] && update_mirrorlist ## 2. Update installer mirrorlist
configure_pacman ## 3. Configure installer pacman (<< performance & usability)
update_keyrings  ## 4. Update Arch Linux installer keyring(s)