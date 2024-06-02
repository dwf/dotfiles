{ config, pkgs, ... }:
{
  home.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    x11.enable = config.xsession.enable;
  };
}
