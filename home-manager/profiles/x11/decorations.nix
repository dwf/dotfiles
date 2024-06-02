{ config, lib, ... }:
let
  wallpaperPath = "~/Pictures/wallpapers/current.jpg";
in {
  imports = [ ../i3status-rust.nix ];

  xsession = {
    windowManager.i3.config.bars = [
        { statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-bottom.toml"; }
    ];
    initExtra = ''
      [ -f ${wallpaperPath} ] && which feh && feh --bg-fill ${wallpaperPath}
    '';
  };
}

