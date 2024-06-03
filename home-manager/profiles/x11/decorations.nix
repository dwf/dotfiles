{ config, lib, ... }:
let
  wallpaperPath = "~/Pictures/wallpapers/current.jpg";
in {

  xsession = lib.mkIf config.xsession.enable {
    initExtra = ''
      [ -f ${wallpaperPath} ] && which feh && feh --bg-fill ${wallpaperPath}
    '';
  };
}

