{ config, lib, pkgs, ... }:
let
  lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
in {
  imports = [
    (import ../i3-sway-common.nix {
      inherit lockCmd;
    })
  ];

  services.screen-locker = {
    inherit lockCmd;
    enable = config.xsession.enable;
    inactiveInterval = 10;
  };

  services.picom = lib.mkIf config.xsession.enable {
    enable = true;
    backend = "glx";
  };
}
