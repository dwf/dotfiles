{ config
, lib
, pkgs
, lockCmd ? "${pkgs.i3lock}/bin/i3lock -n -c 000000"
, ... }:
let
  mod = config.xsession.windowManager.i3.config.modifier;
in
{
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      config = {
        window.titlebar = false;
        terminal = lib.mkDefault "alacritty";
        menu = "rofi -show run";
        keybindings = lib.mkOptionDefault {
          "${mod}+l" = "exec ${lockCmd}";
        };
      };
    };
  };

  services.screen-locker = {
    inherit lockCmd;
    enable = true;
    inactiveInterval = 10;
  };

  services.picom = {
    enable = true;
    backend = "glx";
  };

  home.packages = [ pkgs.xautolock ];
}
