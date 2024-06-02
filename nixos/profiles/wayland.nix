{ pkgs, ... }:
{
  services.xserver.enable = false;

  environment.systemPackages = with pkgs; [
    mako
    swaylock
    wayland
    wl-clipboard
    xwayland
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.sway}/bin/sway";
        user = "greeter";
      };
    };
  };

  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-wlr # Backend for wayland roots
  ];

  security.pam.services.swaylock = {};

  xdg.portal.wlr.enable = true;
}
