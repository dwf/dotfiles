{
  imports = [
    ../../profiles/desktop
    ../../profiles/wayland.nix
    ../../profiles/zsh.nix
    ./hardware-configuration.nix
  ];

  boot.initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;
  hardware.bluetooth.enable = true;
  networking = {
    hostName = "soundwave";
    networkmanager.enable = true;
  };
  services.blueman.enable = true;

  system.stateVersion = "25.05";
}
