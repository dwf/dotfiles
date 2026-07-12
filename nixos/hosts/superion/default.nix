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
    ../../profiles/desktop.nix
    ../../profiles/framework-amd.nix
    ../../profiles/laptop.nix
    ../../profiles/wayland.nix
    ../../profiles/zsh.nix
    inputs.agentspace.nixosModules.hostVirtiofsdNixStore
  ];

  # Socket-activated virtiofsd sharing the host's read-only /nix/store,
  # reused across every agentspace microVM launch (see
  # ../../../vms/agentspace/lib.nix's `nixStoreShareSocket`) instead of
  # virtie spinning up a fresh virtiofsd per launch for the ro-store share.
  # `socketGroup` defaults to "kvm", which dwf is already a member of below.
  agentspace.hostVirtiofsdNixStore.enable = true;

  programs.dconf.enable = true;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
