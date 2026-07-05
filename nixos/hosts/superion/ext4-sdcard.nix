{ pkgs, ... }:
{
  # This module provides an `sdcard` shell script with subcommands "mount" and
  # "unmount" which mounts /dev/sda1 on /mnt/sdcard.

  # It expects either exfat or ext4 formatted cards, and for ext4 it is designed
  # with a particular use case in mind: namely, it is being used in an embedded
  # device that creates lots of stuff as root, and expects files to be owned by
  # root. The script thus uses bindfs to remap root to my user. Finally, the
  # script is added as a sudoers rule so it can be run without a password.
  # Note that fstab entries are intentionally not created given the lack of a
  # fixed filesystem type.

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "sdcard" ''
      UID=$(id -u)
      case $1 in
        mount)
          FSTYPE=$(sudo ${pkgs.util-linux}/bin/blkid -o value -s TYPE /dev/sda1)
          case $FSTYPE in
            exfat|vfat)
              sudo mount -t $FSTYPE -o uid=$UID,gid=100,umask=0022 /dev/sda1 /mnt/sdcard
              ;;
            ext4)
              sudo mount /dev/sda1 /mnt/_sdcard || exit 1
              ${pkgs.bindfs}/bin/bindfs --map=0/$UID /mnt/_sdcard /mnt/sdcard || \
                { sudo umount /mnt/_sdcard; exit 1; }
              ;;
            *)
              echo "Unknown filesystem type: $FSTYPE"
              exit 1
              ;;
          esac
          ;;
        unmount|umount)
          sudo umount /mnt/sdcard || { echo "Failed to unmount /mnt/sdcard"; exit 1; }
          if mountpoint -q /mnt/_sdcard; then
            sudo umount /mnt/_sdcard || echo "Warning: failed to unmount /mnt/_sdcard"
          fi
          ;;
        *)
          echo "Usage: sdcard mount|unmount"
          exit 1
          ;;
      esac
    '')
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/_sdcard 0755 root root -"
    "d /mnt/sdcard 0755 root root -"
  ];

  security.wrappers.sdcard = {
    source = "/run/current-system/sw/bin/sdcard";
    owner = "root";
    group = "root";
    setuid = true;
  };

}
