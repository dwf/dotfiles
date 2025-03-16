{
  boot.initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;

  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "kup";
    interfaces.enp5s0.useDHCP = true;
  };

  system.stateVersion = "24.11";
}
