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

# Script argument(s)
#
# * $1 : Configuration file
# * $2 : stdout log level

# ------------------------------------------------------------------------------
#                                 MODULE HEADER
# ------------------------------------------------------------------------------
source "$1"  # Load configuration file

# Define which network driver function to call:
# This dynamically constructs the name of the network configuration function
# based on the network type defined in the configuration (e.g., NetworkManager).
function_call="conf_$network"

# ------------------------------------------------------------------------------
#                               MODULE FUNCTION(s)
# ------------------------------------------------------------------------------

# Configure system Locale:
# This function sets the hostname, configures /etc/hosts for local resolution,
# enables the desired locale(s), sets the system time zone, generates locale files,
# and configures the console keymap.
conf_locale() {
  echo "$hostname" > /etc/hostname  # Set system hostname
  # Configure /etc/hosts for local hostname resolution
  cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain ${hostname}
EOF
  # Enable the desired primary locale in /etc/locale.gen
  sed -i "s/^#\(${lang}\)/\1/" /etc/locale.gen
  # Enable additional locales, if any
  for locale in "${extra_lang[@]}"; do
    sed -i "s/^#\(${locale}\)/\1/" /etc/locale.gen
  done
  # Set system language and time locale
  echo "LANG=${lang}" > /etc/locale.conf
  echo "LC_TIME=${lc_time}" >> /etc/locale.conf
  eval "locale-gen $2"  # Generate locale
  # Set system timezone and sync hardware clock
  eval "ln -sf /usr/share/zoneinfo/$timezone /etc/localtime $2"
  eval "hwclock --systohc $2"
  echo "KEYMAP=${keyboard}" > /etc/vconsole.conf  # Set console keymap
}

# Configure system User(s):
# This function sets the root password, creates a new user, assigns the user to
# the 'wheel' group for sudo access, and sets the Bash shell as the default shell.
# It also enables sudo privileges for the 'wheel' group in /etc/sudoers.
conf_users() {
  eval "echo 'root:$rootpwd' | chpasswd $2"  # Set root password
  # Add new user, assign to 'wheel' group, and set Bash as default shell
  eval "useradd -m -G wheel -s /bin/bash $username $2"
  eval "echo '$username:$password' | chpasswd $2"  # Set user password
  # Enable sudo for 'wheel' group
  sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers
}

# Configure NetworkManager:
# This function enables NetworkManager and its associated services to manage
# network connectivity.
conf_networkmanager() {
  eval "systemctl enable NetworkManager.service $2"             # Enable 'NetworkManager'
  eval "systemctl enable NetworkManager-wait-online.service $2" # Extra service
}

# Configure package manager (pacman):
# This function configures pacman to use colored output, verbose package lists,
# and parallel downloads (20). It also optimizes 'makepkg' settings and enables
# the multilib repository. Finally, it installs pacman utilities and enables
# automatic cache cleaning via paccache.timer.
conf_pacman() {
  # Enable colored output, fancy progress bar, verbose package lists, and parallel downloads (20)
  sed -i "/etc/pacman.conf" \
    -e "s|^#Color|&\nColor\nILoveCandy|" \
    -e "s|^#VerbosePkgLists|&\nVerbosePkgLists|" \
    -e "s|^#ParallelDownloads.*|&\nParallelDownloads = 20|"
  # Improve 'Makepkg' QoL
  sed -i "/etc/makepkg.conf" \
    -e "s|^#BUILDDIR=.*|&\nBUILDDIR=/var/tmp/makepkg|" \
    -e "s|^PKGEXT.*|PKGEXT='.pkg.tar'|" \
    -e "s|^OPTIONS=.*|#&\nOPTIONS=(docs \!strip \!libtool \!staticlibs emptydirs zipman purge \!debug lto)|" \
    -e "s|-march=.* -mtune=generic|-march=native|" \
    -e "s|^#RUSTFLAGS=.*|&\nRUSTFLAGS=\"-C opt-level=2 -C target-cpu=native\"|" \
    -e "s|^#MAKEFLAGS=.*|&\nMAKEFLAGS=\"-j$(($(nproc --all)-1))\"|"
  eval "pacman -S --noconfirm pacman-contrib $2"  # pacman utils & scripts
  eval "systemctl enable paccache.timer $2"       # Enable automatic cache cleaning
  sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf  # Enable multilib repository
  eval "pacman -Syy $2"                           # Refresh package manager database(s)
}

# Configure mirrorlist:
# This function backs up the current mirrorlist, updates it using the 'reflector'
# tool based on the fastest available servers, and enables the reflector service
# and timer for periodic updates.
conf_mirrorlist() {
  eval "pacman -S --noconfirm reflector $2"
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup  # Backup current mirrorlist
  # Sanitize 'mirrorcountries' into a string if declared
  reflector_countries=$(declare -p mirrorcountries &>/dev/null && (IFS=, ; echo "${mirrorcountries[*]}" | sed 's/ /,/g') || echo "")
  # Run reflector to update mirrorlist
  eval "reflector ${reflector_countries:+--country \"$reflector_countries\"} \
        --protocol https \
        --age 6 \
        --sort rate \
        --save /etc/pacman.d/mirrorlist $2"
  eval "systemctl enable reflector.service $redir_output"  # Enable 'reflector'
  eval "systemctl enable reflector.timer $redir_output"    # Periodic update
}

# Configure system hardening:
# This function installs and configures 'nftables' for firewall rules, applies
# kernel hardening via sysctl, and enables additional protections such as SYN flood
# protection and disabling ICMP redirects.
conf_hardening() {
  # Install 'nftables' and configure firewall rules
  eval "pacman -S --noconfirm nftables $2"  # Install 'nftables'
  NFTABLES_CONF="/etc/nftables.conf"
  bash -c "cat << EOF > $NFTABLES_CONF
#!/usr/sbin/nft -f

table inet filter
delete table inet filter
table inet filter {
  chain input {
    type filter hook input priority filter
    policy drop

    ct state invalid drop comment 'drop invalid connections'
    ct state {established, related} accept comment 'allow established connections'
    iifname lo accept comment 'allow loopback'
    ip protocol icmp accept comment 'allow ICMP'
    meta l4proto ipv6-icmp accept comment 'allow ICMPv6'
    pkttype host limit rate 5/second counter reject with icmpx type admin-prohibited
    counter
  }

  chain forward {
    type filter hook forward priority filter
    policy drop
  }
}
EOF"
  eval "systemctl enable nftables $redir_output"  # Enable 'nftables'

  # Apply kernel network hardening via sysctl
  SYSCTL_CONF="/etc/sysctl.d/90-network.conf"
  bash -c "cat << EOF > $SYSCTL_CONF
# Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Enable SYN flood protection
net.ipv4.tcp_syncookies = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Do not send ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
EOF"
  eval "sysctl --system $redir_output"  # Apply sysctl settings
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
conf_locale       ## 1. Configure system Locale
conf_users        ## 2. Configure system User(s)
$function_call    ## 3. Configure system Network driver dynamically
conf_pacman       ## 4. Configure package manager (pacman)
conf_mirrorlist   ## 5. Configure system package manager mirrorlist server(s)
[ "$hardening" = "yes" ] && conf_hardening  ## 6. (optional) Configure Firewall and Kernel params (++security)