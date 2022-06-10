# Set up a reverse-proxy for a Home Assistant instance that only exposes the
# minimal paths necessary for Google Assistant integration.
{ config, lib, ... }:
with lib;
let
  cfg = config.services.homeAssistantReverseProxy;
in
{
  options.services.homeAssistantReverseProxy = {
    enable = mkEnableOption "Enable the Home Assistant reverse proxy service.";
    hostName = mkOption {
      type = types.str;
      example = "foo.bar.org";
      description = "Hostname to be declared in Caddyfile.";
    };
    homeAssistantUrl = mkOption {
      type = types.str;
      default = "http://homeassistant:8123";
      example = "http://100.101.102.103:8123";
      description = "HTTP URL of the Home Assistant instance.";
    };
    allowSetupPaths = mkOption {
      type = types.bool;
      default = false;
      example = "true";
      description = ''
        Forward paths needed for setup rather than just ordinary operation.
      '';
    };
    extraHostConfig = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Additional Caddy configuration within the reverse proxy's host block.
      '';
    };
    logRollKeep = mkOption {
      type = types.int;
      default = 10;
      example = "10";
      description = ''
        The <literal>roll_keep</literal> option to use for Caddy logging.
      '';
    };
    tlsCertificatePath = mkOption {
      type = types.str;
      default = "/etc/caddy/certificate.pem";
      example = "/etc/caddy/mycoolcertificate.pem";
      description = ''
        Certificate file to use for TLS. Must be readable by the
        <literal>caddy</literal> user.
      '';
    };
    tlsPrivateKeyPath = mkOption {
      type = types.str;
      default = "/etc/caddy/key.pem";
      example = "/etc/caddy/mysupersecretkey.pem";
      description = ''
        Private key file to use for TLS. Must be readable by the
        <literal>caddy</literal> user.
      '';
    };
    logPath = mkOption {
      type = types.str;
      default = "/var/log/caddy/home-assistant-reverse-proxy.log";
      example = "/var/log/caddy/my-caddy-log.log";
      description = ''
        Path to which to save logs.
      '';
    };
  };
  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      extraConfig =
      let
        denyPattern = ''
          not {
            path /api/google_assistant
            path /auth/token'' +
        optionalString cfg.allowSetupPaths ''
            path /auth/*
            path /manifest.json
            path /frontend_latest/*
            path /frontend_es5/*
            path /static/*'' + ''
          }'';
      in ''
      ${cfg.hostName} {
        log {
          output file ${cfg.logPath} {
            roll_keep: ${toString cfg.logRollKeep}
          }
        }
        @deny {
          ${denyPattern}
        }
        tls ${cfg.tlsCertificatePath} ${cfg.tlsPrivateKeyPath}
        respond @deny 403
        reverse_proxy {
          to ${cfg.homeAssistantUrl}
        }
        ${optionalString (!isNull cfg.extraHostConfig) cfg.extraHostConfig}
      }
      '';
    };
  };
}
