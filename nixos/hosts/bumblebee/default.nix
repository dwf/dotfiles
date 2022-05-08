{ config, lib, ... }:
let
  hostName = config.networking.hostName;
  tailscaleDomain = config.services.tailscaleHttpsReverseProxy.tailscaleDomain;
  rootUrl = "https://${hostName}.${tailscaleDomain}/";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = "bumblebee";
  networking.interfaces.ens3.useDHCP = true;

  services = {
    gitea = {
      inherit rootUrl;
      enable = true;
      appName = "gitea@${hostName}";
    };
    tailscaleHttpsReverseProxy = {
      # tailscaleDomain added elsewhere.
      enable = true;
      routes.git = "localhost:3000";
      extraHostConfig = "redir / /git/";
    };
  };
  system.stateVersion = "21.11";
}
