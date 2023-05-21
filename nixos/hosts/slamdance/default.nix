{ lib, pkgs, ... }:
{
  networking = {
    hostName = "slamdance";
    interfaces.wlan0.useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
  };

  security.sudo.wheelNeedsPassword = false;
  hardware.leds.ACT.trigger = "default-on";

  system.stateVersion = "22.11";
}
