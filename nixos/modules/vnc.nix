{ age, config, pkgs, lib, ... }: let
  cfg = config.services.vnc;
in with lib; {
  options = {
    services.vnc = {
      enable = mkEnableOption "";
      geometry = mkOption {
        type = types.str;
        example = "1024x768";
        description = mdDoc ''
          Geometry of the virtual X11 desktop.
        '';
      };
      dpi = mkOption {
        type = types.int;
        example = 72;
        description = mdDoc ''
          Dots-per-inch of the virtual X11 desktop.
        '';
      };
      vncWorkingDirectory = mkOption {
        type = types.path;
        default = "/var/run/tigervnc";
        example = literalExpression "/var/run/vnc";
        description = mdDoc ''
          Working directory for the VNC service. The output of `vncpasswd`
          should be placed inside this directory, called `vncpasswd`.
        '';
      };
      novncPort = mkOption {
        type = types.int;
        example = 6999;
        default = 6080;
        description = mdDoc ''
          Port on which noVNC should listen.
        '';
      };
      user = mkOption {
        type = types.str;
        example = "vnc";
        description = mdDoc ''
          User under which to run the VNC server process.
        '';
      };
      xsession = mkOption {
        type = types.path;
        example = literalExpression ''
          pkgs.writeShellScript "foo" "twm"
        '';
        description = "Path to xsession script used to launch Xvnc.";
      };
    };
  };
  config = mkIf cfg.enable {
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
    systemd.services = {
      novnc = {
        path = with pkgs; [ python3Packages.websockify ps hostname ];
        wantedBy = [ "multi-user.target" ];
        requires = [ "tigervnc.service" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.novnc}/bin/novnc \
              --vnc localhost:5901 \
              --listen ${toString cfg.novncPort} \
              --web ${pkgs.novnc}/share/webapps/novnc
          '';
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
      tigervnc = let
      in {
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-pre.target" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.xorg.xinit}/bin/xinit \
              ${cfg.xsession} -- ${pkgs.tigervnc}/bin/Xvnc \
              :1 \
              PasswordFile=${cfg.vncWorkingDirectory}/vncpasswd \
              -geometry ${cfg.geometry} \
              -dpi ${toString cfg.dpi}
          '';
          RestartSec = "5s";
          WorkingDirectory = cfg.vncWorkingDirectory;
          User = cfg.user;
        };
      };
    };
  };
}
