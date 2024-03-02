{ config, lib, pkgs, ... }:
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
    gitea = rec {
      enable = true;
      domain = "${hostName}.${tailscaleDomain}";
      rootUrl = "https://${domain}/git";
      appName = "gitea@${hostName}";
      settings = {
        picture.DISABLE_GRAVATAR = true;
        "markup.sanitizer.TeX" = {
          ELEMENT = "span";
          ALLOW_ATTR = "class";
          REGEXP = "^\\s*((math(\\s+|$)|inline(\\s+|$)|display(\\s+|$)))+";
        };
        "markup.markdown" = {
          ENABLED = true;
          FILE_EXTENSIONS = ".md,.markdown";
          RENDER_COMMAND = "${pkgs.pandoc}/bin/pandoc -f markdown -t html --filter ${pkgs.pandoc-katex}/bin/pandoc-katex";
        };
      };
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
