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

# Script argument(s)
#
# * $1 : Script operation mode.
#   - create : create a system image - create ./config.yaml
#   - build  : build a system environment (app(s), dir(s), etc)
#
# * $2 : Configuration file - (YAML).
#
# * $3 : Other(s).
#   - silent : silence the operation(s) output (stdout = &> /dev/null)

#!/bin/bash

# ------------------------------------------------------------------------------
#                                     HEADER
# ------------------------------------------------------------------------------
ymlfile="$2"  # Configuration file (YAML)
stdout=""     # Standard output for command operation(s)

# ------------------------------------------------------------------------------
#                              UTILITY FUNCTION(s)
# ------------------------------------------------------------------------------
print_debug() { echo -e "\e[${1}m${2}\e[0m"; }  # Native print/debug output w/ color
print_success() { print_debug "32" "$1"; }      # Green
print_info() { print_debug "36" "$1"; }         # Cyan
print_warning() { print_debug "33" "$1"; }      # Yellow

# ------------------------------------------------------------------------------
#                               ARG(s) FUNCTION(s)
# ------------------------------------------------------------------------------

# Arch Linux
#
# Create an Arch Linux system.
create_arch() {
  # 0 - SETUP
  print_info "[ ] Preparing the machine for the Arch Linux installation ..."
  ./.modules/create/0-setup.sh "$ymlfile" "$stdout" 
  print_success "[*] Machine prepared for the Arch Linux installation."
}

# ------------------------------------------------------------------------------
#                                  MAIN SCRIPT
# - Call of each arg(s) functionalities of the script
# ------------------------------------------------------------------------------

distro_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2)  # Get Distribution ID

[[ "$3" == "silent" ]] && stdout="&> /dev/null"  # Silence the output of the operation(s)

# Arg(s) - 'create'
if [[ "$1" = "create" ]]; then
  # Check prerequisites => root privileges 
  [ "$EUID" -ne 0 ] && { print_warning "Please run as root. Aborting script."; exit 1; }
  # Check prerequisites => system is in UEFI mode
  [[ "$checkefi" = "yes" && ! -d /sys/firmware/efi/efivars ]] && { print_warning "UEFI mode not detected. Aborting script."; exit 1; }

  [[ "$distro_id" = "arch" ]] && create_arch
fi