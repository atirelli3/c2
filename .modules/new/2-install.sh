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

# Get script argument(s)
debug=$1       # Log level (yes or no)
kernel=$2      # Linux kernel
cpu=$3         # CPU driver
network=$4     # Network
bootloader=$5  # Bootloader
osprober=$6    # Enable Os Prober (Windows dualboot)
filesystem=$7  # Filesystem
encrypt=$8     # Disk encryption

# Output rediriction based on debug log level
redir_output=""
[[ "$debug" != "yes" ]] && redir_output="&> /dev/null"

# Gruop pkg(s) by category
LNX="$kernel $kernel-headers linux-firmware"   ## Base Linux packages
BASE="base base-devel git"                     ## Base system packages
BOOTLOADER="$bootloader efibootmgr"            ## Bootloader
EXTRA="sudo"                                   ## Extra packages

# Conditional package addition
[ "$osprober" = "yes" ] && BOOTLOADER+=" os-prober"
[ "$filesystem" = "btrfs" ] && EXTRA+=" btrfs-progs"
[ "$encrypt" = "yes" ] && [ "$filesystem" != "btrfs" ] && EXTRA+=" cryptsetup lvm2"
[ "$encrypt" = "yes" ] && [ "$filesystem" = "btrfs" ] && EXTRA+=" cryptsetup"

eval "pacstrap /mnt $LNX $BASE $cpu-ucode $BOOTLOADER $network $EXTRA $redir_output" # Install base pkg(s)
eval "genfstab -U -p /mnt >> /mnt/etc/fstab $redir_output"                           # Generate fstab file table