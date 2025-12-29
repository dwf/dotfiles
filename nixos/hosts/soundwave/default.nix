{ pkgs, ... }:
{
  imports = [
    ../../profiles/desktop.nix
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
  services = {
    blueman.enable = true;
    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
    };
    zigbee2mqtt = {
      enable = true;
      settings = {
        homeassistant.enabled = true;
        mqtt.server = "mqtt://homeassistant";
        frontend = true;
      };
    };
    tailscale-https-reverse-proxy = {
      enable = false; # TODO: re-enable
      routes.zigbee2mqtt = {
        to = "localhost:8080";
        transparent = true;
      };
    };
  };

  time.timeZone = "America/Toronto";

  system.stateVersion = "25.05";
}
