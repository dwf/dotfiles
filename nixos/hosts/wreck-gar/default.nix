{
  boot.initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;

  imports = [
    ./hardware-configuration.nix
    ../../profiles/jellyfin-kiosk.nix
  ];

  networking = {
    hostName = "wreck-gar";
    networkmanager.enable = true;
  };

  swapDevices = [ { device = "/swapfile"; } ];

  system.stateVersion = "25.05";
}
