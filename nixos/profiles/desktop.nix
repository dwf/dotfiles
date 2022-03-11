{ lib, ... }:
{
  services.xserver = {
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

  # SSD with full disk encryption (except for boot EFI), including swap.
  fileSystems = {
    "/".options = [ "noatime" "compress=lzo" "autodefrag" "commit=100" ];
    "/home".options = [ "noatime" "compress=lzo" "autodefrag" ];
  };
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  services.printing.enable = true;
  sound.enable = true;
  hardware.pulseaudio.enable = true;
}
