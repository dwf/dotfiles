{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking = {
    hostName = "wheeljack";
    interfaces.enp6s0.useDHCP = true;
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "enp6s0";
    };
  };

  services.tailscaleHttpsReverseProxy.enable = true;

  boot = {
    # Kernel support for the Asus B550 motherboard's sensors.
    # https://wiki.archlinux.org/title/lm_sensors#Asus_H97/Z97/Z170/X570/B550_motherboards
    kernelParams = [ "acpi_enforce_resources=lax" ];
    kernelModules = [ "nct6775" "zenpower" ];

    # Use zenpower rather than k10temp for CPU temperatures.
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    blacklistedKernelModules = [ "k10temp" ];

    # Set up encrypted swap. This would have been detected by the hardware scan if
    # I had enabled it before running nixos-generate-config. Live and learn.
    initrd.luks.devices.cryptswap.device = "/dev/nvme0n1p2";
  };

  swapDevices = [
    { device = "/dev/mapper/cryptswap"; }
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
