{ config, lib, ... }:
let
  X11 = config.xsession.enable;
in {
  home.sessionVariables = lib.mkIf X11 {
    GDK_SCALE = 2;
    GDK_DPI_SCALE = 0.5;
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

  home.pointerCursor = {
    size = 48;
  };

  # Suggestions from https://dougie.io/linux/hidpi-retina-i3wm/ for DPI issues
  xresources.properties = lib.mkIf X11 {
    "Xft.dpi" = 192;
    "Xft.autohint" = 0;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.hinting" = 1;
    "Xft.antialias" = 1;
    "Xft.rgba" = "rgb";
  };
}
