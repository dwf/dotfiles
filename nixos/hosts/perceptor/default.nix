{
  boot.initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;

  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "perceptor";
    interfaces.enp1s0.useDHCP = true;  # The rightmost port, closest to power.
  };

  system.stateVersion = "24.11";
}
