# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] Disk Format       |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Partition & format the disk where   |
# |  |      / /   |             | the OS will be installed.           |
# |  `----./ /_   |---------------------------------------------------|
#  \______|____|  |    Owner    | a7ir3                               |
#                 |    GitHub   | https://github.com/atirelli3        |
#                 |   Version   | 1.0.0 (beta)                        |
# ---------------------------------------------------------------------

# !/bin/bash

# Get script argument(s)
target=$1         # Target disk
target_secure=$2  # Fill disk w/ rnd data(s) ?

./.modules/new/1-disk/wipe.sh       # Wipe the disk
# (optional) Fill the disk with random data(s)
if [ "$target_secure" = "yes" ] && { ./.modules/new/1-disk/secure.sh; }
./.modules/new/1-disk/partition.sh  # Partition the disk
if [ "$encrypt" = "yes" ]; then
    root_device="/dev/mapper/${encrypt_label}"  # Set root to encrypted partition
else
    root_device=${target_part}2                 # Set root to non-encrypted partition
fi
./.modules/new/1-disk/${filesystem}.sh
./.modules/new/1-disk/efi.sh