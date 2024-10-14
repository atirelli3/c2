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

# Get script argument(s)
debug=$1  # Log level (yes or no)

source "$2"  # Load configuration file

# Output rediriction based on debug log level
redir_output=""
[[ "$debug" != "yes" ]] && redir_output="&> /dev/null"

# Base setup
loadkeys $keyboard                     # Set keyboard layout
eval "timedatectl set-ntp true $redir_output"  # Enable NTP for time synchronization

# Mirrorlist
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup  # Backup current mirrorlist
# Check if 'mirrorcountries' is declared and sanitize into a string for 'reflector'
# Otherwise empty string (no countries provided)
reflector_countries=$(declare -p mirrorcountries &>/dev/null && IFS=, echo "${mirrorcountries[*]}" || echo "")
# Execute reflector to generate a new mirrorlist
# (if countries are provided use them w/ '--country', otherwise use default)
eval "reflector ${reflector_countries:+--country "$reflector_countries"} \
          --protocol https \
          --age 6 \
          --sort rate \
          --save /etc/pacman.d/mirrorlist $redir_output"
eval "pacman -Syy $redir_output"  # Refresh package manager database(s)

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
eval "pacman -Syy $redir_output"  # Refresh package manager database(s)

# Keyring(s)
eval "pacman -S --noconfirm archlinux-keyring $redir_output"  # Download updated keyrings
eval "pacman-key --init $redir_output"                        # Initialize newer keyrings
eval "pacman -Syy $redir_output"                              # Refresh package manager database(s)
