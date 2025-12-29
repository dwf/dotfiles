{ config, pkgs, ... }:
let
  lockCmd = "pidof swaylock || ${pkgs.swaylock}/bin/swaylock -f -n -c 000000";
in
{
  imports = [
    ./desktop
    (import ./i3-sway-common.nix {
      inherit lockCmd;
      sway = true;
    })
  ];

  home.packages = with pkgs; [
    wl-clipboard
    swaylock
  ];

  # A variety of environment variables that make apps behave.
  home.sessionVariables = {
    GDK_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_SESSION_DESKTOP = "sway";
    XDG_CURRENT_DESKTOP = "sway";
    NIXOS_OZONE_WL = "1";
  };

  services = {
    mako.enable = true;
    swayidle = {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = lockCmd;
        }
      ];
      timeouts = [
        {
          timeout = 240;
          command = lockCmd;
        }
        {
          timeout = 180;
          command = "niri msg action power-off-monitors";
          resumeCommand = "niri msg action power-on-monitors";
        }
        {
          timeout = 60;
          command = "${pkgs.light}/bin/light -O; ${pkgs.light}/bin/light -S 0.5";
          resumeCommand = "${pkgs.light}/bin/light -I";
        }
      ];
    };

    wpaperd = {
      enable = true;
      settings = {
        any.path = "${config.home.homeDirectory}/Pictures/wallpapers/current.jpg";
      };
    };

    swayosd.enable = true;
  };

  # This should obviate running `fc-cache -f`, but did not when upgrading to 25.05.
  fonts.fontconfig.enable = true;
}
