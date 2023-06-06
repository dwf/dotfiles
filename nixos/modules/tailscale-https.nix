{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.tailscaleHttpsReverseProxy;
  routeModule = types.submodule {
    options = {
      to = mkOption {
        type = types.nonEmptyStr;
        example = "localhost:3000";
        description = ''
          Destination for the <literal>reverse_proxy</literal> directive.
        '';
      };
      stripPrefix = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Strip the URL prefix corresponding to the route name/path.
        '';
      };
      transparent = mkEnableOption "Enable transparent proxying (fix websockets).";
    };
  };
in
{
  options.services.tailscaleHttpsReverseProxy = {
    enable = mkEnableOption ''
      Convenient wrapper for HTTPS-over-Tailscale Caddy reverse proxies.

      Redirects http://<host>/uri queries to fully-qualified Tailscale domain
      served over HTTPS with a Tailscale-generated certificate. Optionally
      also reverse-proxies bare HTTP access by other addresses (IP, Bonjour, etc.).
    '';
    tailscaleDomain = mkOption {
      type = types.nonEmptyStr;
      example = "pangolin-unicorn.ts.net";
      description = ''
        Tailscale domain ending in .ts.net.
      '';
    };
    hostName = mkOption {
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "machine1";
      description = ''
        Bare hostname, containing no dots. If not provided, uses
        `networking.hostName`.
      '';
    };
    catchAllHttp = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Accept unencrypted HTTP on all addresses other than the bare hostname.
        Accessing via e.g. a Bonjour <literal>.local</literal> domain or a bare
        IP address will serve unencrypted HTTP, serving as a useful fallback
        for clients without Tailscale running or installed.
      '';
    };
    routes = mkOption {
      type = with types; nullOr (attrsOf routeModule);
      default = null;
      example = "{ git.to = \"localhost:3000\"; }";
      description = ''
        A mapping of top-level /foo/ paths to URLs to which they should be
        reverse-proxied.
      '';
    };
    defaultRoute = mkOption {
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "localhost:12345";
      description = ''
        Optional reverse-proxy to use for paths not matched by the contents
        of <literal>routes</literal>.
      '';
    };

    extraHostConfig = mkOption {
      type = with types; nullOr lines;
      default = null;
      example = "redir / /foo";
      description = ''
        Additional lines concatenated to the host config after reverse
        proxy definitions.
      '';
    };
  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.tailscale = {
      enable = true;
      permitCertUid = "caddy";
    };

    services.caddy = {
      enable = true;

      # Disable the default specification of the CA as this currently interferes
      # with Tailscale integration.
      acmeCA = null;

      globalConfig = "auto_https off";
      extraConfig = let
        hostName = if (isNull cfg.hostName) then
          config.networking.hostName
        else
          cfg.hostName;
        transparentConfig = ''
          {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
        mkReverseProxy = name: dest: (''
            redir /${name} /${name}/   # Handle lack of trailing slash.
            route /${name}/* {
        '' + ((optionalString dest.stripPrefix) ''
              uri strip_prefix /${name}
        '') + ''
              reverse_proxy ${dest.to} ${optionalString dest.transparent transparentConfig}
            }
          '');
        reverseProxies = optionals
          (! isNull cfg.routes)
          (mapAttrsToList mkReverseProxy cfg.routes);
        defaultReverseProxy = optionalString (! isNull cfg.defaultRoute) ''
          route /* {
            reverse_proxy ${cfg.defaultRoute}
          }
        '';
        extraHostConfig = optionalString
          (! isNull cfg.extraHostConfig)
          cfg.extraHostConfig;
        declarationHeader = concatStrings [
          (optionalString cfg.catchAllHttp "http://, ")
          "https://${hostName}.${cfg.tailscaleDomain}"
        ];
      in
       ''
           http://${hostName} {
             redir https://${hostName}.${cfg.tailscaleDomain}{uri}
           }
           ${declarationHeader} {
             ${concatStringsSep "\n" reverseProxies}
             ${defaultReverseProxy}
             ${extraHostConfig}
           }
        '';
    };
  };
}
