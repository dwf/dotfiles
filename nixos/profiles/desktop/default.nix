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
  };

  xdg.portal = {
    enable = true;  # xdg portal is used for tunneling permissions to flatpak
    config.common.format = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # SSD with full disk encryption (except for boot EFI), including swap.
  fileSystems = let
    btrfsCommon = [ "defaults" "noatime" "compress=zstd" ];
  in {
    "/".options = btrfsCommon ++ [ "commit=100" ];
    "/home".options = btrfsCommon;
  };
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  services.printing.enable = true;
  sound.enable = true;
  hardware = {
    pulseaudio.enable = true;
    opengl.driSupport32Bit = true;
  };

  environment.systemPackages = with pkgs.xorg; [
    xdpyinfo
    xev
    xkill
  ];
}
