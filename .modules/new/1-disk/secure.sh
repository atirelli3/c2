#!/bin/bash

# Get script argument(s)
debug=$1   # Log level (yes or no)
target=$2  # Target disk

# Output rediriction based on debug log level
redir_output=""
[[ "$debug" != "yes" ]] && redir_output="&> /dev/null"

# Fill disk with random data for security
eval "cryptsetup open --type plain --batch-mode -d /dev/urandom $target target $redir_output"
eval "dd if=/dev/zero of=/dev/mapper/target bs=1M status=progress oflag=direct $redir_output"
cryptsetup close target