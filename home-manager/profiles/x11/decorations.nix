{ config, lib, ... }:
let
  wallpaperPath = "~/Pictures/wallpapers/current.jpg";
in {

  xsession = lib.mkIf config.xsession.enable {
    windowManager.i3.config.bars =  (import ../i3-sway-common.nix { inherit config lib pkgs; }).bars;
    initExtra = ''
      [ -f ${wallpaperPath} ] && which feh && feh --bg-fill ${wallpaperPath}
    '';
  };
}

