{ lib, ... }: {
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
}
