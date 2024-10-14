# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] Arch configuration|
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Base Arch Linux system              |
# |  |      / /   |             | configuration.                      |
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

echo "$hostname" > /etc/hostname  # Set system hostname
cat > /etc/hosts << EOF           # Configure /etc/hosts for local hostname resolution
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain ${hostname}
EOF
sed -i "s/^#\(${lang}\)/\1/" /etc/locale.gen  # Enable the desired primary locale in /etc/locale.gen
for locale in "${extra_lang[@]}"; do          # Enable additional locales, if any
  sed -i "s/^#\(${locale}\)/\1/" /etc/locale.gen
done
echo "LANG=${lang}" > /etc/locale.conf         # Set system language/locale
echo "LC_TIME=${lc_time}" >> /etc/locale.conf  # Set locale for time display
eval "locale-gen $redir_output"                # Generate locale
# Set system timezone and sync hardware clock
eval "ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime $redir_output"
eval "hwclock --systohc $redir_output"
echo "KEYMAP=${keyboard}" > /etc/vconsole.conf  # Set console keymap