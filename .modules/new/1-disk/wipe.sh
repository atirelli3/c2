#!/bin/bash

# Get script argument(s)
debug=$1   # Log level (yes or no)
target=$2  # Target disk

# Output rediriction based on debug log level
redir_output=""
[[ "$debug" != "yes" ]] && redir_output="&> /dev/null"

eval "wipefs -af $target $redir_output"               # Wipe all data
eval "sgdisk --zap-all --clear $target $redir_output" # Clear partition table
eval "sgdisk -a 2048 -o $target $redir_output"        # Align sectors to 2048
eval "partprobe $target $redir_output"                # Inform system of disk changes