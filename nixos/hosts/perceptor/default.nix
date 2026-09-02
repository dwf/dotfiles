{
  boot.initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;

  imports = [
    ./hardware-configuration.nix
    ./jellyfin.nix
  ];

  networking = {
    hostName = "perceptor";
    interfaces.enp1s0.useDHCP = true;  # The rightmost port, closest to power.
  };

  # Serve the Jellyfin container over HTTPS on perceptor's Tailscale domain.
  # tailscaleDomain is injected elsewhere.
  services.tailscale-https-reverse-proxy = {
    enable = true;
    defaultRoute = "10.233.51.2:8096";
  };

  system.stateVersion = "24.11";
}
