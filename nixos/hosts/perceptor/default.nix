{
  boot.initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;

  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "perceptor";
  };

  system.stateVersion = "24.11";
}
