{
  boot.initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;

  imports = [
    ./hardware-configuration.nix
    ../../profiles/kodi-jellyfin.nix
  ];

  networking = {
    hostName = "wreck-gar";
    networkmanager.enable = true;
  };

  # Bluetooth game controllers (e.g. reflashed Stadia pad) pair over the
  # Chromebox's built-in Intel radio.
  hardware.bluetooth.enable = true;

  swapDevices = [ { device = "/swapfile"; } ];

  system.stateVersion = "25.05";
}
