{ config, pkgs, ... }:
{
  imports = [
    ./btrfs.nix # TODO(dwf): better place for this
  ];

  environment.systemPackages = with pkgs; [
    alsa-utils # for alsamixer
    pavucontrol
    pulseaudio # for pactl
  ];

  services = {
    accounts-daemon.enable = true; # Required for flatpak+xdg
    flatpak.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
    };
    rtkit.enable = true;
  };

  xdg.portal = {
    enable = true; # xdg portal is used for tunneling permissions to flatpak
    config.common.format = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.printing.enable = true;
  hardware = {
    graphics.enable32Bit = true;
  };

  programs.steam.enable = true;
  fileSystems."/mnt/steam" = {
    inherit (config.fileSystems."/") device fsType;
    options = [
      "defaults"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "subvol=@steam"
      "user"
      "exec"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/steam 0755 dwf users"
  ];
}
