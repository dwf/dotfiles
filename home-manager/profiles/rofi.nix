{ lib, pkgs, ... }:
{
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
}
