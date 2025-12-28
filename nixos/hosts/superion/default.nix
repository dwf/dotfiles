{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./ext4-sdcard.nix
    ../../profiles/desktop
    ../../profiles/framework-amd.nix
    ../../profiles/laptop.nix
    ../../profiles/wayland.nix
    ../../profiles/zsh.nix
    inputs.niri-flake.nixosModules.niri
  ];

  programs.dconf.enable = true;
  nixpkgs.overlays = [
    inputs.niri-flake.overlays.niri
  ];
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  networking.hostName = "superion";

  services = {
    mullvad-vpn.enable = true;
    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
    };
  };

  security.rtkit.enable = true;

  fileSystems."/nix".options = [ "noatime" ];

  hardware.flipperzero.enable = true;

  # This didn't get added to hardware-configuration.nix, for some reason.
  boot.initrd.luks.devices."cryptswap".device =
    "/dev/disk/by-uuid/a550eea0-45e0-47b0-89a3-b5cf85625f62";

  users.users.dwf.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
  };

  # linuxPackages_latest on 24.11 broke the fingerprint reader.
  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_11;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
