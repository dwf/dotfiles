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
    gitea = {
      enable = true;
      appName = "gitea@${hostName}";
      settings = {
        server = rec {
          DOMAIN = "${hostName}.${tailscaleDomain}";
          ROOT_URL = "https://${DOMAIN}/git";
        };
        "markup.jupyter" = {
          ENABLED = true;
          FILE_EXTENSIONS = ".ipynb";
          RENDER_COMMAND = "${pkgs.python3Packages.nbconvert}/bin/jupyter-nbconvert --stdin --stdout --to html --template basic";

          IS_INPUT_FILE = false;
        };
        "markup.sanitizer.jupyter" = {
          ELEMENT = "div";
          ALLOW_ATTR = "class";
          REGEXP = "";
        };
        "markup.sanitizer.jupyter.img" = {
          ALLOW_DATA_URI_IMAGES = true;
        };
        picture.DISABLE_GRAVATAR = true;
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

  system.activationScripts.gitea = lib.stringAfter [ "var" ] (let
    giteaCustom = config.services.gitea.customDir;
  in ''
    rm -rf ${giteaCustom}/public ${giteaCustom}/templates/custom
    mkdir -p ${giteaCustom}/public/assets/css
    mkdir -p ${giteaCustom}/templates/custom/
    ${pkgs.python3Packages.pygments}/bin/pygmentize -S default -f html -a .highlight > ${giteaCustom}/public/assets/css/pygments.css
    cat >${giteaCustom}/templates/custom/header.tmpl << EOF
    <link rel="stylesheet" href="{{AppSubUrl}}/assets/css/pygments.css" />
    EOF
  '');

  system.stateVersion = "21.11";
}
