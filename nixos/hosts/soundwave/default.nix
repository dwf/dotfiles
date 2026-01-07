{ pkgs, ... }:
{
  imports = [
    ../../profiles/desktop.nix
    ../../profiles/wayland.nix
    ../../profiles/zsh.nix
    ./hardware-configuration.nix
  ];

  boot = {
    kernelParams = [
      # This one doesn't seem to be necessary for now.
      # "snd_hda_intel.dmic_detect=0"
      "snd_intel_dspcfg.dsp_driver=1" # Added to fix HDMI sound output, unsure if strictly necessary
      "snd_hda_intel.power_save=0" # Attempt to fix skipping
    ];
    initrd.luks.devices.cryptroot.tryEmptyPassphrase = true;
  };
  hardware = {
    bluetooth.enable = true;
    enableAllFirmware = true; # Added to fix HDMI sound output, unsure if strictly necessary
  };
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
        availability.enabled = true;
        homeassistant.enabled = true;
        mqtt.server = "mqtt://homeassistant";
        frontend = true;
      };
    };
    tailscale-https-reverse-proxy = {
      enable = true;
      routes.zigbee2mqtt = {
        to = "localhost:8080";
        transparent = true;
      };
    };
  };

  # Steam client is just a black screen without this.
  programs.steam.package = pkgs.steam.override {
    extraArgs = "-system-composer";
  };

  time.timeZone = "America/Toronto";

  system.stateVersion = "25.05";
}
