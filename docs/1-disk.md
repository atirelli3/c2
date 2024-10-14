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

- **`wipefs -af /dev/sda`**:
  - **`-a`**: Wipes all filesystem signatures on the disk.
  - **`-f`**: Forces the wipe, ignoring potential warnings.
  - This ensures that any existing filesystem data or metadata on `/dev/sda` is completely erased.

- **`sgdisk --zap-all --clear /dev/sda`**:
  - **`--zap-all`**: Wipes all partition tables and metadata.
  - **`--clear`**: Removes all partitions and resets the disk to a blank state.
  - This command removes all partition data from the disk, preparing it for a new partitioning scheme.

- **`sgdisk -a 2048 -o /dev/sda`**:
  - **`-a 2048`**: Aligns the disk sectors to 2048, ensuring better performance for SSDs.
  - **`-o`**: Creates a new GPT partition table.
  - This aligns the sectors properly for modern storage devices and creates a new GPT layout on the disk.

- **`partprobe /dev/sda`**:
  - Informs the operating system to re-read the partition table and apply any changes immediately.

---

## 2. Securing the Disk

To ensure that no previous data can be recovered, fill the disk with random data:

```bash
cryptsetup open --type plain --batch-mode -d /dev/urandom /dev/sda target
dd if=/dev/zero of=/dev/mapper/target bs=1M status=progress oflag=direct
cryptsetup close target
```

- **`cryptsetup open --type plain --batch-mode -d /dev/urandom /dev/sda target`**:
  - **`--type plain`**: Uses plain mode for encryption, meaning no persistent key is stored.
  - **`--batch-mode`**: Skips interactive password prompts.
  - **`-d /dev/urandom`**: Uses `/dev/urandom` to generate random data for the encryption key.
  - This command opens the disk `/dev/sda` with a randomly generated key, allowing data to be written securely.

- **`dd if=/dev/zero of=/dev/mapper/target bs=1M status=progress oflag=direct`**:
  - **`if=/dev/zero`**: Input file is `/dev/zero`, meaning the disk is filled with zeroes.
  - **`of=/dev/mapper/target`**: Output file is the encrypted disk, ensuring all data is securely overwritten.
  - **`bs=1M`**: Sets the block size to 1 MB, which speeds up the operation.
  - **`status=progress`**: Displays the progress of the operation.
  - **`oflag=direct`**: Directs `dd` to bypass system caching for a more accurate operation.
  - This command fills the disk with zeros, ensuring that no old data remains on the disk.

- **`cryptsetup close target`**:
  - Closes the encrypted disk, rendering the temporary encryption key useless and securing the data.

---

## 3. Partitioning the Disk

Create two partitions: one for the EFI system partition (ESP) and another for the root filesystem. Run the following commands:

```bash
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:ESP /dev/sda   # EFI partition (512MiB)
sgdisk -n 0:0:0 -t 0:8300 -c 0:rootfs /dev/sda      # Root partition (rest of the disk)
partprobe /dev/sda                                  # Inform system of disk changes
```

- **`sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:ESP /dev/sda`**:
  - **`-n 0:0:+512MiB`**: Creates a new partition with a size of 512MB.
  - **`-t 0:ef00`**: Sets the partition type to `ef00`, which is the identifier for the EFI System Partition (ESP).
  - **`-c 0:ESP`**: Labels the partition as `ESP`.
  - This command creates a 512MB partition that will be used as the EFI partition.

- **`sgdisk -n 0:0:0 -t 0:8300 -c 0:rootfs /dev/sda`**:
  - **`-n 0:0:0`**: Creates a new partition that occupies the remaining space on the disk.
  - **`-t 0:8300`**: Sets the partition type to `8300`, which is the identifier for the Linux filesystem.
  - **`-c 0:rootfs`**: Labels the partition as `rootfs`.
  - This command creates a root partition using the remaining disk space.

- **`partprobe /dev/sda`**:
  - Informs the system of the changes to the partition table, making the new partitions immediately usable.

---

## 4. Encrypting the Root Partition (Optional)

To encrypt the root partition using LUKS, run the following commands:

```bash
sgdisk -t 2:8309 /dev/sda                              # Set partition 2 type to LUKS
partprobe /dev/sda                                     # Inform system of disk changes
echo -n "changeme" | cryptsetup --type luks2 -v -y --batch-mode luksFormat /dev/sda2 --key-file=-
echo -n "changeme" | cryptsetup open --perf-no_read_workqueue --perf-no_write_workqueue --persistent /dev/sda2 cryptdev --key-file=-
```

- **`sgdisk -t 2:8309 /dev/sda`**:
  - **`-t 2:8309`**: Sets partition 2 (root partition) to type `8309`, which is for encrypted Linux (LUKS).
  - This command marks the root partition for encryption.

- **`echo -n "changeme" | cryptsetup --type luks2 -v -y --batch-mode luksFormat /dev/sda2 --key-file=-`**:
  - **`--type luks2`**: Uses LUKS version 2 for encryption.
  - **`-v`**: Verbose mode, providing more output for troubleshooting.
  - **`-y`**: Asks for confirmation before proceeding.
  - **`--batch-mode`**: Runs in non-interactive mode, suitable for scripts.
  - **`--key-file=-`**: Reads the key from stdin (the key "changeme" in this case).
  - This command formats the partition `/dev/sda2` with LUKS encryption using the provided key.

- **`echo -n "changeme" | cryptsetup open --perf-no_read_workqueue --perf-no_write_workqueue --persistent /dev/sda2 cryptdev --key-file=-`**:
  - **`open`**: Opens the encrypted partition.
  - **`--perf-no_read_workqueue --perf-no_write_workqueue`**: Optimizes the performance of the encrypted volume.
  - **`--persistent`**: Makes the encrypted mapping persistent.
  - **`cryptdev`**: The name used to map the encrypted partition.
  - This command opens the LUKS-encrypted root partition and makes it available as `/dev/mapper/cryptdev`.

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
btrfs

 subvolume create /mnt/@log          # Log
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

- **`mkfs.btrfs -L archlinux /dev/sda2`**:
  - **`-L archlinux`**: Assigns the label `archlinux` to the Btrfs filesystem.
  - This command formats the root partition as a Btrfs filesystem.

- **`btrfs subvolume create /mnt/@home`**: Creates Btrfs subvolumes for different system components (system, home, snapshots, etc.).

- **`mount -o rw,noatime,compress-force=zstd:1,space_cache=v2,subvol=@ /dev/sda2 /mnt`**:
  - **`rw`**: Mounts the filesystem as read-write.
  - **`noatime`**: Disables updates to the file access time to improve performance.
  - **`compress-force=zstd:1`**: Forces Zstandard compression at level 1 for better performance.
  - **`space_cache=v2`**: Enables advanced space caching for improved filesystem performance.
  - **`subvol=@`**: Mounts the subvolume for the root filesystem (`@`).
  - This command mounts the Btrfs subvolumes with appropriate options for better performance and compression.

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

- **`mkfs.vfat -F32 -n ESP /dev/sda1`**:
  - **`-F32`**: Specifies FAT32 as the filesystem format.
  - **`-n ESP`**: Assigns the label `ESP` to the partition.
  - This command formats the EFI partition as FAT32.

- **`mkdir -p /mnt/esp`**: Creates the mountpoint `/mnt/esp`.

- **`mount /dev/sda1 /mnt/esp`**: Mounts the EFI partition to `/mnt/esp`.

---
