# Disk Formatting Guide

This guide explains how to format, partition, and configure your disk for a new system installation. It covers wiping the disk, partitioning, optional encryption, and creating filesystems (Btrfs and ext4).

## 1. Wiping the Disk

To completely erase any existing data and partition tables from the target disk, run the following commands:

```bash
wipefs -af /dev/sda               # Wipe all filesystem signatures
sgdisk --zap-all --clear /dev/sda  # Clear all partition tables
sgdisk -a 2048 -o /dev/sda         # Align sectors to 2048
partprobe /dev/sda                 # Inform the system about changes to the disk
```

> [!WARNING]  
> **Wiping the disk will delete all data** on `/dev/sda`. Make sure you have selected the correct disk to avoid accidental data loss.

---

## 2. Securing the Disk

To ensure that no previous data can be recovered, fill the disk with random data:

```bash
cryptsetup open --type plain --batch-mode -d /dev/urandom /dev/sda target
dd if=/dev/zero of=/dev/mapper/target bs=1M status=progress oflag=direct
cryptsetup close target
```

> [!IMPORTANT]  
> **Filling the disk with random data** may take a long time, depending on the size of the target disk. Make sure you have enough time allocated for this step.

---

## 3. Partitioning the Disk

Create two partitions: one for the EFI system partition (ESP) and another for the root filesystem. Run the following commands:

```bash
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:ESP /dev/sda   # EFI partition (512MiB)
sgdisk -n 0:0:0 -t 0:8300 -c 0:rootfs /dev/sda      # Root partition (rest of the disk)
partprobe /dev/sda                                  # Inform system of disk changes
```

> [!CAUTION]  
> Ensure the correct partition sizes are specified before running the commands. Incorrect partition sizes may lead to insufficient space for system components.

---

## 4. Encrypting the Root Partition (Optional)

To encrypt the root partition using LUKS, run the following commands:

```bash
sgdisk -t 2:8309 /dev/sda                              # Set partition 2 type to LUKS
partprobe /dev/sda                                     # Inform system of disk changes
echo -n "changeme" | cryptsetup --type luks2 -v -y --batch-mode luksFormat /dev/sda2 --key-file=-
echo -n "changeme" | cryptsetup open --perf-no_read_workqueue --perf-no_write_workqueue --persistent /dev/sda2 cryptdev --key-file=-
```

> [!TIP]  
> Encryption ensures that the contents of your root partition are secure and protected against unauthorized access. Make sure to securely store the encryption key.

### Steps:

1. **Set partition type to LUKS**: Changes the partition type to LUKS, marking it for encryption.
2. **Encrypt the partition**: Uses the encryption key `"changeme"` to encrypt the partition.
3. **Open the encrypted partition**: Opens the encrypted partition as `cryptdev`, making it accessible for the system.

---

## 5. Creating Filesystems

This section covers creating and mounting the necessary filesystems for your system. The guide is divided into two subsections: Btrfs and ext4.

### 5.1 Btrfs Filesystem

To format the root partition as Btrfs, create subvolumes, and mount them, run the following commands:

```bash
mkfs.btrfs -L archlinux /dev/sda2    # Format as Btrfs with label "archlinux"
mount /dev/sda2 /mnt                 # Mount root partition
```

#### Create Btrfs Subvolumes

```bash
btrfs subvolume create /mnt/@             # System
btrfs subvolume create /mnt/@home         # Home
btrfs subvolume create /mnt/@snapshots    # Snapshots
btrfs subvolume create /mnt/@cache        # Cache
btrfs subvolume create /mnt/@log          # Log
btrfs subvolume create /mnt/@tmp          # Temp
btrfs subvolume create /mnt/@libvirt      # Libvirt
btrfs subvolume create /mnt/@docker       # Docker
btrfs subvolume create /mnt/@flatpak      # Flatpak
btrfs subvolume create /mnt/@distrobox    # Distrobox
btrfs subvolume create /mnt/@containers   # Containers
```

#### Mount Btrfs Subvolumes

```bash
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@ /dev/sda2 /mnt        # Mount system subvolume
mkdir -p /mnt/{home,.snapshots,var/cache,var/log,var/tmp,var/lib/libvirt,var/lib/docker,var/lib/flatpak,var/lib/distrobox,var/lib/containers}  # Create mountpoints
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@home /dev/sda2 /mnt/home            # Home
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@snapshots /dev/sda2 /mnt/.snapshots # Snapshots
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@cache /dev/sda2 /mnt/var/cache      # Cache
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@log /dev/sda2 /mnt/var/log          # Log
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@tmp /dev/sda2 /mnt/var/tmp          # Temp
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@libvirt /dev/sda2 /mnt/var/lib/libvirt  # Libvirt
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@docker /dev/sda2 /mnt/var/lib/docker   # Docker
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@flatpak /dev/sda2 /mnt/var/lib/flatpak # Flatpak
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@distrobox /dev/sda2 /mnt/var/lib/distrobox # Distrobox
mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@containers /dev/sda2 /mnt/var/lib/containers # Containers
```

---

### 5.2 Ext4 Filesystem

> [!IMPORTANT]  
> The ext4 section is still under construction and will be added later.

---

## 6. Formatting the EFI System Partition (ESP)

To format the EFI system partition and mount it, run the following commands:

```bash
mkfs.vfat -F32 -n ESP /dev/sda1    # Format the ESP partition as FAT32 with label "ESP"
mkdir -p /mnt/esp                  # Create the mountpoint
mount /dev/sda1 /mnt/esp           # Mount the ESP partition
```

> [!NOTE]  
> The EFI System Partition (ESP) must be formatted as FAT32 to be compatible with UEFI firmware.

---
