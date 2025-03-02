{
  config,
  lib,
  nixosModules,
  pkgs,
  ...
}:
let
  inherit (config.networking) hostName;
  inherit (config.services.tailscale-https-reverse-proxy) tailscaleDomain;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "bumblebee";
    interfaces.ens3.useDHCP = true;

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "ens3";
    };
  };

  containers.miniflux = {
    privateNetwork = true;
    enableTun = true;
    hostAddress = "10.233.50.1";
    localAddress = "10.233.50.2";
    config =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.kmod ];
        imports = [ nixosModules.tailscale-https-reverse-proxy ];
        services = {
          miniflux = {
            enable = true;
            adminCredentialsFile = "/etc/miniflux/admin-credentials";
            config = {
              CLEANUP_ARCHIVE_READ_DAYS = 180;
              CLEANUP_ARCHIVE_UNREAD_DAYS = 730;
              HTTP_CLIENT_TIMEOUT = 60;
              POLLING_PARSE_ERROR_LIMIT = 10;
              POLLING_FREQUENCY = 90;
            };
          };
          tailscale.enable = true;
          tailscale-https-reverse-proxy = {
            enable = true;
            inherit tailscaleDomain;
            defaultRoute = "localhost:8080";
          };
        };
        system.stateVersion = "24.11";
      };
  };

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
    tailscale-https-reverse-proxy = {
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

  system.activationScripts.gitea = lib.stringAfter [ "var" ] (
    let
      giteaCustom = config.services.gitea.customDir;
    in
    ''
      rm -rf ${giteaCustom}/public ${giteaCustom}/templates/custom
      mkdir -p ${giteaCustom}/public/assets/css
      mkdir -p ${giteaCustom}/templates/custom/
      ${pkgs.python3Packages.pygments}/bin/pygmentize -S default -f html -a .highlight > ${giteaCustom}/public/assets/css/pygments.css
      cat >${giteaCustom}/templates/custom/header.tmpl << EOF
      <link rel="stylesheet" href="{{AppSubUrl}}/assets/css/pygments.css" />
      EOF
    ''
  );

  system.stateVersion = "21.11";
}
