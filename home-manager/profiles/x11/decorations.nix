{ config, lib, pkgs, ... }:
let
  wallpaperPath = "~/Pictures/wallpapers/current.jpg";
in
{
  programs.i3status-rust = {
    enable = lib.mkDefault true;
    bars.bottom = {
      settings = {
        theme.theme = "solarized-dark";
        font = "font pango:DejaVu Sans Mono, Icons 12";
        icons_format = " <span font_family='FantasqueSansMono Nerd Font'>{icon}</span> ";
      };
      icons = "material-nf";
      blocks = [
        {
          block = "net";
        }
        {
          block = "time";
          interval = 60;
          format = "$timestamp.datetime(f:'%a %d/%m %R')";
        }
      ];
    };
  };

  home.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    x11.enable = true;
  };

  xsession = {
    windowManager.i3.config.bars = [
        { statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-bottom.toml"; }
    ];
    initExtra = ''
      [ -f ${wallpaperPath} ] && which feh && feh --bg-fill ${wallpaperPath}
    '';
  };
}

