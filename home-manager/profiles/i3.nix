{ config, lib, pkgs, ... }:
let
  mod = config.xsession.windowManager.i3.config.modifier;
  lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
in
{
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      config = {
        window.titlebar = false;
        terminal = lib.mkDefault "alacritty";
        menu = "rofi -show drun";
        keybindings = lib.mkOptionDefault {
          "${mod}+l" = lib.mkDefault "exec ${lockCmd}";
          "Shift+${mod}+d" = "exec rofi -show run";
          "Ctrl+${mod}+e" = "exec rofi -show emoji";
        };
      };
    };
  };

  services.screen-locker = {
    lockCmd = lib.mkDefault lockCmd;
    enable = true;
    inactiveInterval = 10;
  };

  services.picom = {
    enable = true;
    backend = "glx";
  };
}
