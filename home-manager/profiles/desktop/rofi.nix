{ lib, pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    font = lib.mkDefault "DejaVu Sans Mono 8";
    terminal = "alacritty";
    theme = "Arc-Dark";
    plugins = lib.mkDefault (
      with pkgs;
      [
        rofi-calc
        rofi-emoji
      ]
    );
    extraConfig = {
      modi = lib.concatStringsSep "," [
        "calc"
        "drun"
        # "emoji"
        "filebrowser"
        "run"
        "ssh"
      ];
    };
  };
}
