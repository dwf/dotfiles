{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../profiles/framework-amd.nix
    ../../profiles/laptop.nix
    ../../profiles/hidpi.nix
    ];

  networking.hostName = "superion";

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  # This didn't get added to hardware-configuration.nix, for some reason.
  boot.initrd.luks.devices."cryptswap".device = "/dev/disk/by-uuid/a550eea0-45e0-47b0-89a3-b5cf85625f62";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
