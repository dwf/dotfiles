{ config, lib, pkgs, ... }:
let
  wallpaperPath = "~/Pictures/wallpapers/current.jpg";
in
{
  programs.i3status-rust = {
    enable = lib.mkDefault true;
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

  home.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    x11.enable = true;
  };

  xsession.windowManager.i3 = {
    bars = [
        { statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-bottom.toml"; }
    ];

    initExtra = ''
      [ -f ${wallpaperPath} ] && feh --bg-fill ${wallpaperPath}
    '';
  };
}

