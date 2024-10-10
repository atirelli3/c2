# !/bin/bash

# Fill disk with random data for security
cryptsetup open --type plain --batch-mode -d /dev/urandom $target target &> /dev/null
dd if=/dev/zero of=/dev/mapper/target bs=1M status=progress oflag=direct &> /dev/null
cryptsetup close target