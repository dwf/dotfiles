{ config, pkgs, ... }:
{
  programs.steam.enable = true;
  fileSystems."/mnt/steam" = {
    inherit (config.fileSystems."/") device fsType;
    options = [ "defaults" "noatime" "compress=zstd" "autodefrag" "subvol=@steam" "user" "exec" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/steam 0755 dwf users"
  ];
}
