{ config, pkgs, ... }:
let
  lockCmd = "${pkgs.swaylock}/bin/swaylock -n -c 000000";
in {
  imports = [
    ./desktop
    (import ./i3-sway-common.nix {
      inherit lockCmd;
      sway = true;
    })
  ];

  xsession.enable = false;

  # A variety of environment variables that make apps behave.
  home.sessionVariables = {
    GDK_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_SESSION_DESKTOP = "sway";
    XDG_CURRENT_DESKTOP = "sway";
    NIXOS_OZONE_WL = "1";
  };

  programs.rofi = {
    font = "DejaVu Sans Mono 8";
    # rofi plugin derivations include mainline rofi as a dependency, which
    # breaks if the package is overridden below. I'd upstream this to
    # home-manager but I don't immediately know how you'd obtain the unwrapped
    # derivation from the wrapped one.
    plugins = with pkgs;
      let
        override-rofi = p: p.override { rofi-unwrapped = rofi-wayland-unwrapped; };
      in
      map override-rofi [
        rofi-calc
        # rofi-emoji
      ];

    # The default will run in XWayland, with ugly font scaling.
    package = pkgs.rofi-wayland;
  };

  services.swayidle = {
    enable = true;
    events = [ { event = "before-sleep"; command = lockCmd; } ];
    timeouts = [
      { timeout = 300; command = lockCmd; }
      { timeout = 60; command = "${pkgs.light}/bin/light -O; ${pkgs.light}/bin/light -S 0.5"; resumeCommand = "${pkgs.light}/bin/light -I"; }
    ];
    systemdTarget = "sway-session.target";
  };

  systemd.user.services.swayidle.Unit.PartOf = [ "sway-session.target" ];

  programs.wpaperd = {
    enable = true;
    settings = {
      any.path = "${config.home.homeDirectory}/Pictures/wallpapers/current.jpg";
    };
  };

  systemd.user.services.wpaperd = {
    Unit = {
      Description = "wpaperd";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wpaperd}/bin/wpaperd";
    };
    Install = { WantedBy = [ "sway-session.target" ]; };
  };

  services.swayosd.enable = true;
}
