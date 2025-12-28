{ config, lib, ... }:
let
  cfg = {
    enable = true;
    provider = "manual";
    latitude = "51.5007";
    longitude = "0.1246";
    tray = config.xsession.enable; # gammastep just gives me a red frowny face
  };
in
{
  services.gammastep = lib.mkIf (!config.xsession.enable) cfg;
}
