{ config, lib, pkgs, ... }:
let
  hostName = config.networking.hostName;
  tailscaleDomain = config.services.tailscaleHttpsReverseProxy.tailscaleDomain;
in
{
  # TODO(dwf): Remove this overlay when the patch hits stable.
  nixpkgs.overlays = [
    (self: super: let
      websockifyPatch = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/13cc17cc53eab4a59fe5530a53faef1eabaafc0f/pkgs/applications/networking/novnc/websockify.patch";
        sha512 = "327032c1f8e1a5b89f1ce355fdc3d534afd3c9740d4e7963781857409299e2a4f9687fd14be8a07e5f81b5a6a1d97dfae8d9ff62cdc665b8324926c65f41eab8";
      };
    in {
      novnc = super.novnc.overrideAttrs (old: {
        patches = with pkgs.python3.pkgs; [
          (pkgs.substituteAll {
            src = websockifyPatch;
            inherit websockify;
          })
        ];
      });
    })
  ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = "bumblebee";
  networking.interfaces.ens3.useDHCP = true;

  services = {
    gitea = rec {
      enable = true;
      domain = "${hostName}.${tailscaleDomain}";
      rootUrl = "https://${domain}/git";
      appName = "gitea@${hostName}";
      settings.picture.DISABLE_GRAVATAR = true;
    };
    tailscaleHttpsReverseProxy = {
      # tailscaleDomain added elsewhere.
      enable = true;
      routes = {
        git.to = "localhost:3000";
        _vnc = {
          to = "localhost:${toString config.services.vnc.novncPort}";
          stripPrefix = true;
        };
      };
      extraHostConfig = ''
        redir / /git/
        redir /vnc /vnc/
        redir /vnc/ /_vnc/vnc.html?resize=scale
        route /websockify {
          reverse_proxy http://localhost:${toString config.services.vnc.novncPort}
        }
        redir /dist /dist/
        file_server /dist/* {
          root /var/www
          browse
        }
      '';
    };
    vnc = {
      user = "dwf";
      enable = true;
      geometry = "2560x1600";
      dpi = 192;
    };
  };
  system.stateVersion = "21.11";
}
