# Arch Linux Installation Guide

This guide covers the essential commands for installing Arch Linux, including the base system, bootloader, and additional packages based on the system configuration.

## 1. Install Base Linux Packages

To install the base Linux packages, system tools, bootloader, and other necessary components, use the following command:

```bash
pacstrap /mnt linux-zen linux-zen-headers linux-firmware base base-devel git intel-ucode grub efibootmgr networkmanager sudo
```

- **`pacstrap /mnt`**: This command installs packages to the mounted target (`/mnt`).
- **`linux-zen`**: Installs the `linux-zen` kernel, which is optimized for responsiveness and performance.
- **`linux-zen-headers`**: Installs the headers required for compiling kernel modules.
- **`linux-firmware`**: Provides essential firmware files for hardware components.
- **`base`**: Installs the base Arch Linux system.
- **`base-devel`**: Installs tools required for compiling software (e.g., `gcc`, `make`).
- **`git`**: Installs the `git` version control system.
- **`intel-ucode`**: Installs microcode updates for Intel CPUs (you can replace this with `amd-ucode` for AMD CPUs).
- **`grub`**: Installs the GRUB bootloader.
- **`efibootmgr`**: A tool to manage EFI boot entries, necessary for systems using UEFI.
- **`networkmanager`**: Installs NetworkManager for managing network connections.
- **`sudo`**: Installs `sudo`, which allows non-root users to execute root-level commands.

> [!TIP]  
> If your system uses a different CPU architecture (e.g., AMD), replace `intel-ucode` with `amd-ucode`.

---

## 2. Add Bootloader and Extra Packages Conditionally

### a. If You Are Dual-Booting with Another OS (e.g., Windows)

If you need to detect other operating systems (like Windows), you can install the `os-prober` package:

```bash
pacstrap /mnt os-prober
```

- **`os-prober`**: This tool detects other operating systems on the disk and adds them to the GRUB boot menu.

### b. If You Are Using the Btrfs Filesystem

If you're formatting your root partition with Btrfs, install the necessary tools for Btrfs:

```bash
pacstrap /mnt btrfs-progs
```

- **`btrfs-progs`**: This package contains utilities for managing Btrfs filesystems, including creating and mounting Btrfs subvolumes.

### c. If You Are Using Disk Encryption

If your system uses encryption, install the necessary encryption tools:

#### For non-Btrfs encrypted systems:

```bash
pacstrap /mnt cryptsetup lvm2
```

- **`cryptsetup`**: A tool for setting up encrypted filesystems using LUKS.
- **`lvm2`**: Logical Volume Manager, required if you're using encrypted LVM.

#### For Btrfs encrypted systems:

```bash
pacstrap /mnt cryptsetup
```

- **`cryptsetup`**: The same tool is used to manage encrypted filesystems in both Btrfs and non-Btrfs systems.

---

## 3. Generate the Filesystem Table (fstab)

Once the packages have been installed, you need to generate the `fstab` file, which tells the system how to mount partitions at boot time. Use the following command:

```bash
genfstab -U -p /mnt >> /mnt/etc/fstab
```

- **`genfstab -U -p /mnt`**: Automatically generates the `fstab` file based on the UUIDs of the partitions.
- **`>> /mnt/etc/fstab`**: Appends the generated entries to `/mnt/etc/fstab`, which will be used by the installed system.

---
