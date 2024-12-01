{ pkgs, lib, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../profiles/desktop
    ../../profiles/framework-amd.nix
    ../../profiles/laptop.nix
    ../../profiles/wayland.nix
  ];

  programs.dconf.enable = true;

  networking.hostName = "superion";

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  security.rtkit.enable = true;

  fileSystems."/nix".options = [ "noatime" ];

  # This didn't get added to hardware-configuration.nix, for some reason.
  boot.initrd.luks.devices."cryptswap".device = "/dev/disk/by-uuid/a550eea0-45e0-47b0-89a3-b5cf85625f62";

  # linuxPackages_latest on 24.11 broke the fingerprint reader.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_11;

  # Allows home-manager installed shells to be the login shell.
  environment.etc."shells".text = lib.mkAfter ''
    /home/dwf/.nix-profile/bin/zsh
    /home/dwf/.nix-profile/bin/fish
  '';

  users.users.dwf = {
    useDefaultShell = false;
    shell = "/home/dwf/.nix-profile/bin/zsh";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
