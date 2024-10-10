## Basic Setup Script for Arch Linux

This script is designed to configure some essential aspects of an Arch Linux installation, such as keyboard layout, updating the repository mirror list, configuring `pacman`, and installing the necessary GPG keys for secure package management.

### 1. Initial Keyboard Layout and Time Synchronization Setup

```bash
loadkeys us  # Set the keyboard layout to Italian
timedatectl set-ntp true &> /dev/null  # Enable NTP to synchronize the system clock
```

> [!NOTE]  
> If you are unsure about the correct keyboard layout for your system, you can list all available layouts with the following command:  
> ```bash
> localectl list-keymaps
> ```

- **`loadkeys us`**: sets the keyboard layout to US (`us`).
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

> [!TIP]  
> You can refer to the [Arch Wiki Reflector Guide](https://wiki.archlinux.org/title/Reflector) for detailed usage instructions on how to generate an optimal mirror list for your location.

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

- **`pacman -S archlinux-keyring`**: installs the `archlinux-keyring` package.
- **`pacman-key --init`**: initializes the GPG keyrings used by `pacman` to verify the integrity and authenticity of packages.
- **`pacman -Syy`**: refreshes the package database once more.

---
