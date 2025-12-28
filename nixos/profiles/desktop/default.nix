{ pkgs, ... }:
{
  imports = [
    ../btrfs.nix # TODO(dwf): better place for this
    ./steam.nix
  ];

  services = {
    flatpak.enable = true;
    accounts-daemon.enable = true; # Required for flatpak+xdg
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
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
}
