# !/bin/bash

pacstrap /mnt $LNX $BASE $CPU $BOOTLOADER $NETWORK $CRYPT $EXTRA &> /dev/null
genfstab -U -p /mnt >> /mnt/etc/fstab &> /dev/null  # Generate fstab file table