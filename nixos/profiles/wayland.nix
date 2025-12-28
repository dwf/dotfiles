{ pkgs, ... }:
{
  services.xserver.enable = false;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --remember --cmd ${pkgs.niri-unstable}/bin/niri-session";
        user = "greeter";
      };
    };
  };

  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-wlr # Backend for wayland roots
  ];

  security.pam.services.swaylock = { };

  xdg.portal.wlr.enable = true;
}
