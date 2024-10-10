# 0 - Basic Setup for Arch Linux installation

This step is designed to configure some essential aspects of an Arch Linux installation, such as keyboard layout, updating the repository mirror list, configuring `pacman`, and installing the necessary GPG keys for secure package management.

## 1. Initial Keyboard Layout and Time Synchronization Setup

```bash
loadkeys it  # Set the keyboard layout to Italian
timedatectl set-ntp true &> /dev/null  # Enable NTP to synchronize the system clock
```

- **`loadkeys it`**: sets the keyboard layout to Italian (`it`).
- **`timedatectl set-ntp true`**: enables NTP (Network Time Protocol) to automatically synchronize the system clock.

### 2. Backup and Update the Mirror List

```bash
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup  # Backup the current mirror list
reflector --country Italy,Germany,France \
          --protocol https \
          --age 6 \
          --sort rate \
          --save /etc/pacman.d/mirrorlist &> /dev/null
pacman -Syy &> /dev/null  # Update the package database
```

- **`cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup`**: creates a backup of the current mirror list.
- **`reflector`**: updates the `pacman` mirror list. Options used:
  - `--country Italy,Germany,France`: selects mirrors from Italy, Germany, and France.
  - `--protocol https`: only selects mirrors that use the HTTPS protocol.
  - `--age 6`: selects mirrors updated in the last 6 hours.
  - `--sort rate`: sorts mirrors by speed.
  - `--save /etc/pacman.d/mirrorlist`: saves the updated mirror list to `/etc/pacman.d/mirrorlist`.
- **`pacman -Syy`**: forces a refresh of the package database (with `yy` option).

### 3. Configuring `pacman`

```bash
sed -i "/etc/pacman.conf" \
    -e "s|^#Color|&\nColor\nILoveCandy|" \
    -e "s|^#VerbosePkgLists|&\nVerbosePkgLists|" \
    -e "s|^#ParallelDownloads.*|&\nParallelDownloads = 20|"
pacman -Syy &> /dev/null  # Refresh the package database
```

- **`sed -i "/etc/pacman.conf"`**: modifies the `pacman` configuration file to enable several options:
  - **`#Color`**: enables colored output in `pacman`.
  - **`#ILoveCandy`**: adds an animation during package downloads.
  - **`#VerbosePkgLists`**: shows detailed information about the packages to be installed.
  - **`#ParallelDownloads`**: enables parallel downloads, allowing up to 20 packages to be downloaded simultaneously.
- **`pacman -Syy`**: refreshes the package database.

### 4. Managing GPG Keys

```bash
pacman -S --noconfirm archlinux-keyring &> /dev/null  # Install the Arch Linux keyring package
pacman-key --init &> /dev/null  # Initialize the keyring
pacman -Syy &> /dev/null  # Refresh the package database
```

- **`pacman -S --noconfirm archlinux-keyring`**: installs the `archlinux-keyring` package without requiring confirmation.
- **`pacman-key --init`**: initializes the GPG keyrings used by `pacman` to verify the integrity and authenticity of packages.
- **`pacman -Syy`**: refreshes the package database once more.

---
