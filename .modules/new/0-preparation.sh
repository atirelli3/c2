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

# !/bin/bash

# Base setup
loadkeys $keyboard                     # Set keyboard layout
timedatectl set-ntp true &> /dev/null  # Enable NTP for time synchronization

# Mirrorlist
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup  # Backup current mirrorlist
# Check if 'mirrorcountries' is declared and sanitize into a string for 'reflector'
# Otherwise empty string (no countries provided)
reflector_countries=$(declare -p mirrorcountries &>/dev/null && IFS=, echo "${mirrorcountries[*]}" || echo "")
# Execute reflector to generate a new mirrorlist
# (if countries are provided it use them w/ '--country', otherwise use default)
reflector ${reflector_countries:+--country "$reflector_countries"} \
          --protocol https \
          --age 6 \
          --sort rate \
          --save /etc/pacman.d/mirrorlist &> /dev/null
pacman -Syy &> /dev/null  # Refresh package manager database(s)

# Configure pacman:
#
# - color output
# - fancy progress bar
# - verbose package list
# - parallel download(s)
sed -i "/etc/pacman.conf" \
    -e "s|^#Color|&\nColor\nILoveCandy|" \
    -e "s|^#VerbosePkgLists|&\nVerbosePkgLists|" \
    -e "s|^#ParallelDownloads.*|&\nParallelDownloads = 20|"
pacman -Syy &> /dev/null  # Refresh package manager database(s)

# Keyring(s)
pacman -S --noconfirm archlinux-keyring &> /dev/null  # Download updated keyrings
pacman-key --init &> /dev/null                        # Initialize newer keyrings
pacman -Syy &> /dev/null                              # Refresh package manager database(s)