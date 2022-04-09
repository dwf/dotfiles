{ config, lib, pkgs, ... }:
let
  lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
  mod = config.xsession.windowManager.i3.config.modifier;
in
{
  programs.i3status-rust = {
    enable = true;
    bars.bottom = {
      settings = {
        theme = "solarized-dark";
        icons_format = " <span font_family='FantasqueSansMono Nerd Font'>{icon}</span> ";
        font = "font pango:DejaVu Sans Mono, Icons 12";
      };
      icons = "material-nf";
      blocks = [
        {
          block = "networkmanager";
        }
        {
          block = "time";
          interval = 60;
          format = "%a %d/%m %R";
        }
      ];
    };
  };

  programs.rofi = {
    enable = true;
    font = "DejaVu Sans Mono 18";
    terminal = "alacritty";
    theme = "Arc-Dark";
    plugins = with pkgs; [ rofi-calc rofi-emoji ];
    extraConfig = {
      modi = lib.concatStringsSep "," [
        "calc"
        "drun"
        "emoji"
        "filebrowser"
        "run"
        "ssh"
      ];
    };
  };

  services.screen-locker = {
    inherit lockCmd;
    enable = true;
    inactiveInterval = 10;
  };

  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      config = {
        window.titlebar = false;
        terminal = "alacritty";
        menu = "rofi -show run";
        bars = [
          { statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-bottom.toml"; }
        ];
        keybindings = lib.mkOptionDefault {
          "${mod}+l" = "exec ${lockCmd}";
        };
      };
    };
    pointerCursor = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
    };
    initExtra = ''
      [ -f ~/Pictures/wallpaper.jpg ] && ${pkgs.feh}/bin/feh --bg-fill ~/Pictures/wallpapers/current.jpg
    '';
  };
  services.picom = {
    enable = true;
    backend = "glx";
  };
}
