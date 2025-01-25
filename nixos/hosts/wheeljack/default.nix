{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../profiles/amd.nix
    ../../profiles/desktop
    ../../profiles/wayland.nix
  ];

  networking = {
    firewall.trustedInterfaces = [ "tailscale0" ];
    hostName = "wheeljack";
    interfaces.enp6s0 = {
      useDHCP = true;
      wakeOnLan.enable = true;
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp6s0";
    };
  };

  services = {
    blueman.enable = true;
    tailscale-https-reverse-proxy.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest; # For bluetooth driver

  hardware = {
    opengl.enable = true;
    bluetooth.enable = true;
  };

  boot = {
    # Kernel support for the Asus B550 motherboard's sensors.
    # https://wiki.archlinux.org/title/lm_sensors#Asus_H97/Z97/Z170/X570/B550_motherboards
    kernelParams = [ "acpi_enforce_resources=lax" ];
    kernelModules = [
      "nct6775"
      "zenpower"
    ];

    # Use zenpower rather than k10temp for CPU temperatures.
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    blacklistedKernelModules = [ "k10temp" ];

    initrd = {
      # Set up encrypted swap. This would have been detected by the hardware scan if
      # I had enabled it before running nixos-generate-config. Live and learn.
      luks.devices.cryptswap.device = "/dev/nvme0n1p2";

      # Enable SSH during initrd.
      network = {
        enable = true;
        ssh = {
          enable = true;
          hostKeys = [
            "/etc/secrets/initrd/ssh_host_rsa_key"
            "/etc/secrets/initrd/ssh_host_ed25519_key"
          ];
          authorizedKeys = config.users.users.dwf.openssh.authorizedKeys.keys;
        };
      };
      availableKernelModules = [ "igc" ];
    };

    binfmt.emulatedSystems = [
      "armv6l-linux"
      "armv7l-linux"
      "aarch64-linux"
    ];
  };

  swapDevices = [
    { device = "/dev/mapper/cryptswap"; }
  ];

  # Don't mount /boot/efi by default.
  fileSystems."/boot/efi" = {
    device = "/dev/nvme0n1p3";
    fsType = "vfat";
    options = [
      "noexec"
      "nosuid"
      "noauto"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
