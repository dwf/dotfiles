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
