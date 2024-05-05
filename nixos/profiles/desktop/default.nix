{ lib, pkgs, ... }:
{
  imports = [ ./steam.nix ];

  services = {
    xserver = {
      enable = true;
      layout = "us";
      displayManager = {
        lightdm = {
          enable = true;
          greeters.gtk.enable = true;
        };

        # Defined in nixos/modules/user-xsession.nix
        defaultSession = lib.mkDefault "user-xsession";
      };
    };
    flatpak.enable = true;
    accounts-daemon.enable = true;  # Required for flatpak+xdg
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
    enable = true;  # xdg portal is used for tunneling permissions to flatpak
    config.common.format = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # SSD with full disk encryption (except for boot EFI), including swap.
  fileSystems = let
    btrfsOptions = [ "defaults" "noatime" "compress=zstd" "noautodefrag" "commit=100" ];
  in {
    "/".options = btrfsOptions;
    "/home".options = btrfsOptions;
  };
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  services.printing.enable = true;
  sound.enable = true;
  hardware = {
    opengl.driSupport32Bit = true;
  };

  environment.systemPackages = with pkgs.xorg; [
    xdpyinfo
    xev
    xkill
  ];
}
