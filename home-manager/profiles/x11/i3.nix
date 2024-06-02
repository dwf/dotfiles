{ config, lib, pkgs, ... }:
let
  i3-sway-common = (import ../i3-sway-common.nix { inherit config lib pkgs; });
in
{
  xsession = {
    enable = lib.mkDefault true;
    windowManager.i3 = {
      enable = true;
      inherit (i3-sway-common) config extraConfig;
    };
  };

  services.screen-locker = {
    inherit (i3-sway-common) lockCmd;
    enable = config.xsession.enable;
    inactiveInterval = 10;
  };

  services.picom = lib.mkIf config.xsession.enable {
    enable = true;
    backend = "glx";
  };
}
