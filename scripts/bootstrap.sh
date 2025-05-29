# Disk layout for FDE single-partition btrfs.
# No separate swap partition (a swapfile is more flexible, and separate
# partition only really useful if you want hibernate). Note that compression
# mount options don't seem to take when using nixos-generate-config.

# Create a partition table
parted /dev/sda -- mklabel gpt

# Unencrypted boot. 4GB should be more than enough to future-proof
parted /dev/sda -- mkpart ESP fat32 1MB 4GB
parted /dev/sda -- set 1 boot on

# Rest of the disk is one btrfs
parted /dev/sda -- mkpart primary 4G 100%

# Create a LUKS-encrypted block device
cryptsetup luksFormat --type luks2 /dev/sda2  # Enter password

# Open the encrypted partition as /dev/mapper/cryptroot
cryptsetup open /dev/sda2 cryptroot

# Format the underlying partitions
mkfs.fat -F 32 -n EFI /dev/sda1  # Format the unencrypted EFI partition
mkfs.btrfs /dev/mapper/cryptroot  # Should I be using -c here?

# Mount once for subvolume creation
mount -o defaults,noatime,compress=zstd /dev/mapper/cryptroot /mnt

# Create volumes on the btrfs root. Can also create one for steam, etc.
btrfs subvolume create /mnt/@rootnix
btrfs subvolume create /mnt/@home

# Remount with new volumes
umount /mnt
mount -o compress=zstd,subvol=@rootnix /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot /mnt/home /mnt/steam
mount -o compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home
mkdir /mnt/boot/efi

# Use mount options fmask=0077,dmask=0077 so that random seed isn't world
# readable, which is a security hole
mount -o fmask=0077,dmask=0077 /dev/sda1 /mnt/boot/efi

# Enable swap if you're using nixos-generate-config to auto-detect mounts
# We don't want this file subject to copy-on-write, so we create a 0-length
# file and then set its extended attributes to disable COW before filling
# it with the desired amount of zeros.
truncate -s 0 /mnt/swapfile
chattr +C /mnt/swapfile
dd if=/dev/zero of=/mnt/swapfile bs=4M count=4000

# Format and activate the swap
mkswap /mnt/swapfile
swapon /mnt/swapfile
