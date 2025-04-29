{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    font-awesome_5
    font-awesome_6
  ];
  programs.i3status-rust = {
    enable = lib.mkDefault true;
    bars.bottom = {
      settings = {
        theme.theme = "solarized-dark";
        font = "DejaVuSansM Nerd Font:style=Regular";
        icons_format = " {icon} ";
      };
      icons = "awesome6";
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
