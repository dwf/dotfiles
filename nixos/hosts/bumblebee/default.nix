{ config, lib, ... }:
let
  hostName = config.networking.hostName;
  tailscaleDomain = config.services.tailscaleHttpsReverseProxy.tailscaleDomain;
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
      enable = true;
      rootUrl = "https://${hostName}.${tailscaleDomain}/git";
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
