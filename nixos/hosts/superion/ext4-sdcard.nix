{ pkgs, ... }:
{
  # Set up two mounts: /mnt/_sdcard, which is a simple ext4 mount, and
  # /mnt/sdcard, which is a bindfs mount which remaps uid 0 (root) to
  # uid 1000 (dwf).
  fileSystems = {
    "/mnt/_sdcard" = {
      device = "/dev/sda1";
      fsType = "ext4";
      options = [
        "noauto"
        "user"
      ];
    };
    "/mnt/sdcard" = {
      device = "/mnt/_sdcard";
      fsType = "fuse.bindfs";
      options = [
        "map=0/1000"
        "noauto"
      ];
      depends = [ "/mnt/_sdcard" ];
    };
  };

  # Shell script for easy management of the raw and bindfs mounts.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "sdcard" ''
      if [ "$1" != "mount" -a "$1" != "unmount" -a "$1" != "umount" -o $# -ne 1 ]; then
        echo "usage: $0 <mount/u[n]mount>"
        exit 1
      fi
      if [ "$1" == "mount" ]; then
        if [ -n "$(mount |grep '/mnt/sdcard')" ]; then
          echo "Already mounted"
          exit 1
        fi
        mount /mnt/_sdcard
        sudo mount /mnt/sdcard
      else
        sudo umount /mnt/sdcard
        umount /mnt/_sdcard
      fi
    '')
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/_sdcard 0755 dwf users -"
    "d /mnt/sdcard 0755 dwf users -"
  ];

  security.sudo.extraRules = [
    {
      users = [ "dwf" ];
      commands = [
        {
          command = "/run/wrappers/bin/mount /mnt/sdcard";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/wrappers/bin/umount /mnt/sdcard";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
